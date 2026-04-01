import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Store coordinates — Gopalganj, Bihar
const double kStoreLat = 26.47956893329922;
const double kStoreLng = 84.44273819616502;
const double kServiceRadiusKm = 7.0;

enum LocationStatus { initial, loading, inRange, outOfRange, denied, error }

class LocationState {
  final LocationStatus status;
  final Position? position;
  final double? distanceKm;
  final String? error;

  const LocationState({
    this.status = LocationStatus.initial,
    this.position,
    this.distanceKm,
    this.error,
  });

  bool get isInRange => status == LocationStatus.inRange;

  LocationState copyWith({
    LocationStatus? status,
    Position? position,
    double? distanceKm,
    String? error,
  }) =>
      LocationState(
        status: status ?? this.status,
        position: position ?? this.position,
        distanceKm: distanceKm ?? this.distanceKm,
        error: error ?? this.error,
      );
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  /// Haversine formula — returns distance in km
  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> checkLocation() async {
    state = state.copyWith(status: LocationStatus.loading);

    // Check service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        status: LocationStatus.error,
        error: 'Location services are disabled. Please enable GPS.',
      );
      return;
    }

    // Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: LocationStatus.denied,
        error: 'Location permission denied.',
      );
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final dist = _distanceBetween(pos.latitude, pos.longitude, kStoreLat, kStoreLng);
      state = state.copyWith(
        position: pos,
        distanceKm: dist,
        status: dist <= kServiceRadiusKm
            ? LocationStatus.inRange
            : LocationStatus.outOfRange,
      );
    } catch (e) {
      state = state.copyWith(
        status: LocationStatus.error,
        error: 'Could not get location: $e',
      );
    }
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);
