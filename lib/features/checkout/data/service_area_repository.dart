import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceAreaResult {
  final bool available;
  final String? areaName;
  final String? city;
  final double? distanceKm;
  final double? radiusKm;

  const ServiceAreaResult({
    required this.available,
    this.areaName,
    this.city,
    this.distanceKm,
    this.radiusKm,
  });
}

class ServiceAreaRepository {
  final SupabaseClient _client;
  ServiceAreaRepository(this._client);

  /// Distance-based check via Supabase RPC (Haversine in SQL)
  Future<ServiceAreaResult> checkByCoordinates(
      double lat, double lng) async {
    final result = await _client.rpc('check_service_area', params: {
      'user_lat': lat,
      'user_lng': lng,
    });

    final list = result as List;
    if (list.isEmpty) return const ServiceAreaResult(available: false);

    final row = list.first as Map<String, dynamic>;
    return ServiceAreaResult(
      available: true,
      areaName: row['name'] as String?,
      city: row['city'] as String?,
      distanceKm: double.tryParse(row['distance_km'].toString()),
      radiusKm: double.tryParse(row['radius_km'].toString()),
    );
  }
}
