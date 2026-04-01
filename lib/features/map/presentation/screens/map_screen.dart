import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/location_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  static const _storeLatLng = LatLng(kStoreLat, kStoreLng);

  Set<Marker> _buildMarkers(LocationState loc) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('store'),
        position: _storeLatLng,
        infoWindow: const InfoWindow(
          title: 'S2 Bazaar Store',
          snippet: 'Siwan, Bihar',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
    if (loc.position != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: LatLng(loc.position!.latitude, loc.position!.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    return markers;
  }

  Set<Circle> _buildCircle() => {
        Circle(
          circleId: const CircleId('serviceArea'),
          center: _storeLatLng,
          radius: kServiceRadiusKm * 1000, // metres
          fillColor: const Color(0x22EF5350),
          strokeColor: AppColors.primary,
          strokeWidth: 2,
        ),
      };

  Future<void> _moveCameraToUser(LocationState loc) async {
    if (loc.position == null) return;
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
          loc.position!.latitude < kStoreLat
              ? loc.position!.latitude - 0.05
              : kStoreLat - 0.05,
          loc.position!.longitude < kStoreLng
              ? loc.position!.longitude - 0.05
              : kStoreLng - 0.05,
        ),
        northeast: LatLng(
          loc.position!.latitude > kStoreLat
              ? loc.position!.latitude + 0.05
              : kStoreLat + 0.05,
          loc.position!.longitude > kStoreLng
              ? loc.position!.longitude + 0.05
              : kStoreLng + 0.05,
        ),
      ),
      80,
    ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).checkLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);

    ref.listen(locationProvider, (_, next) {
      if (next.position != null) _moveCameraToUser(next);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _storeLatLng,
              zoom: 12,
            ),
            onMapCreated: (ctrl) => _mapController.complete(ctrl),
            markers: _buildMarkers(loc),
            circles: _buildCircle(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── Top bar ────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('S2 Bazaar — 6 km service area',
                              style: AppTextStyles.captionBold()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom status card ─────────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: _StatusCard(loc: loc, onRetry: () {
              ref.read(locationProvider.notifier).checkLocation();
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Status Card ──────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final LocationState loc;
  final VoidCallback onRetry;

  const _StatusCard({required this.loc, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.card,
      ),
      child: switch (loc.status) {
        LocationStatus.initial || LocationStatus.loading => const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 14),
              Text('Detecting your location…'),
            ],
          ),
        LocationStatus.inRange => _RangeRow(
            icon: '✅',
            color: AppColors.green,
            bgColor: AppColors.greenSoft,
            title: 'We deliver to you!',
            subtitle:
                '${loc.distanceKm!.toStringAsFixed(1)} km from store · within 10 km zone',
          ),
        LocationStatus.outOfRange => _RangeRow(
            icon: '📍',
            color: AppColors.primary,
            bgColor: AppColors.primarySoft,
            title: 'Outside delivery zone',
            subtitle:
                '${loc.distanceKm!.toStringAsFixed(1)} km away · service radius is 10 km',
            action: _ActionButton(label: 'Retry', onTap: onRetry),
          ),
        LocationStatus.denied => _RangeRow(
            icon: '🔒',
            color: Colors.orange,
            bgColor: const Color(0xFFFFF3E0),
            title: 'Location permission needed',
            subtitle: 'Allow location access to check delivery availability',
            action: _ActionButton(label: 'Allow', onTap: onRetry),
          ),
        LocationStatus.error => _RangeRow(
            icon: '⚠️',
            color: Colors.red,
            bgColor: const Color(0xFFFFEBEE),
            title: 'Location unavailable',
            subtitle: loc.error ?? 'Something went wrong',
            action: _ActionButton(label: 'Retry', onTap: onRetry),
          ),
      },
    );
  }
}

class _RangeRow extends StatelessWidget {
  final String icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final Widget? action;

  const _RangeRow({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.bodyBold(color: color)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.caption(),
                  maxLines: 2),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: AppTextStyles.captionBold(color: Colors.white)),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Icon(icon, size: 16, color: AppColors.text1),
      ),
    );
  }
}
