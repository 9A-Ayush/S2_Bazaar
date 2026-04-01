import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';
import '../data/service_area_repository.dart';

final serviceAreaRepositoryProvider = Provider<ServiceAreaRepository>((ref) {
  return ServiceAreaRepository(Supabase.instance.client);
});

// ─── State ────────────────────────────────────────────────────────────────────
enum ServiceCheckStatus { idle, loading, available, unavailable, error }

class ServiceAreaState {
  final ServiceCheckStatus status;
  final ServiceAreaResult? result;
  final String? error;
  final double? checkedLat;
  final double? checkedLng;

  const ServiceAreaState({
    this.status = ServiceCheckStatus.idle,
    this.result,
    this.error,
    this.checkedLat,
    this.checkedLng,
  });

  bool get isAvailable => status == ServiceCheckStatus.available;
  bool get isLoading => status == ServiceCheckStatus.loading;

  ServiceAreaState copyWith({
    ServiceCheckStatus? status,
    ServiceAreaResult? result,
    String? error,
    double? checkedLat,
    double? checkedLng,
  }) =>
      ServiceAreaState(
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
        checkedLat: checkedLat ?? this.checkedLat,
        checkedLng: checkedLng ?? this.checkedLng,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class ServiceAreaNotifier extends StateNotifier<ServiceAreaState> {
  final ServiceAreaRepository _repo;
  ServiceAreaNotifier(this._repo) : super(const ServiceAreaState());

  /// Check using live GPS
  Future<void> checkWithGPS() async {
    state = state.copyWith(status: ServiceCheckStatus.loading);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: ServiceCheckStatus.error,
          error: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: ServiceCheckStatus.error,
          error: 'Location permission denied.',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await _checkCoords(pos.latitude, pos.longitude);
    } catch (e) {
      state = state.copyWith(
        status: ServiceCheckStatus.error,
        error: 'Could not get location: $e',
      );
    }
  }

  /// Check using coordinates from a saved address (geocoding only — no GPS).
  Future<void> checkWithAddress(AddressModel address) async {
    state = state.copyWith(status: ServiceCheckStatus.loading);
    try {
      final coords = await _geocodePincode(address.pincode, address.city);
      if (coords == null) {
        state = state.copyWith(
          status: ServiceCheckStatus.error,
          error: 'Could not verify this address. Please try a different address.',
        );
        return;
      }
      await _checkCoords(coords.$1, coords.$2);
    } catch (e) {
      state = state.copyWith(
        status: ServiceCheckStatus.error,
        error: 'Service check failed: $e',
      );
    }
  }

  /// Check with explicit lat/lng (e.g. from map picker)
  Future<void> checkWithCoords(double lat, double lng) async {
    state = state.copyWith(status: ServiceCheckStatus.loading);
    await _checkCoords(lat, lng);
  }

  Future<void> _checkCoords(double lat, double lng) async {
    try {
      final result = await _repo.checkByCoordinates(lat, lng);
      state = state.copyWith(
        status: result.available
            ? ServiceCheckStatus.available
            : ServiceCheckStatus.unavailable,
        result: result,
        checkedLat: lat,
        checkedLng: lng,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServiceCheckStatus.error,
        error: 'Service check failed: $e',
      );
    }
  }

  void reset() => state = const ServiceAreaState();

  /// Approximate geocoding using known city coordinates.
  /// In production replace with Google Geocoding API call.
  Future<(double, double)?> _geocodePincode(
      String pincode, String city) async {
    // Store location — Gopalganj, Bihar
    const storeCoords = (26.47956893329922, 84.44273819616502);

    const cityCoords = <String, (double, double)>{
      'gopalganj': storeCoords,
    };

    final key = city.toLowerCase().trim();
    if (cityCoords.containsKey(key)) return cityCoords[key];

    // Pincode fallback
    if (pincode.trim() == '841428') return storeCoords;

    return null;
  }
}

final serviceAreaProvider =
    StateNotifierProvider<ServiceAreaNotifier, ServiceAreaState>((ref) {
  return ServiceAreaNotifier(ref.read(serviceAreaRepositoryProvider));
});
