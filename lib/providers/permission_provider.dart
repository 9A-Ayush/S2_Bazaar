import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermStatus { initial, granted, denied, permanentlyDenied }

class PermissionState {
  final PermStatus location;
  final PermStatus notification;

  const PermissionState({
    this.location = PermStatus.initial,
    this.notification = PermStatus.initial,
  });

  bool get allGranted =>
      location == PermStatus.granted && notification == PermStatus.granted;

  bool get locationGranted => location == PermStatus.granted;
  bool get notificationGranted => notification == PermStatus.granted;

  PermissionState copyWith({PermStatus? location, PermStatus? notification}) =>
      PermissionState(
        location: location ?? this.location,
        notification: notification ?? this.notification,
      );
}

PermStatus _fromStatus(PermissionStatus s) {
  if (s.isGranted) return PermStatus.granted;
  if (s.isPermanentlyDenied) return PermStatus.permanentlyDenied;
  return PermStatus.denied;
}

class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(const PermissionState());

  /// Check current status without requesting
  Future<void> checkStatuses() async {
    final loc = await Permission.locationWhenInUse.status;
    final notif = await Permission.notification.status;
    state = PermissionState(
      location: _fromStatus(loc),
      notification: _fromStatus(notif),
    );
  }

  /// Request both permissions
  Future<void> requestAll() async {
    final results = await [
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();

    state = PermissionState(
      location: _fromStatus(results[Permission.locationWhenInUse]!),
      notification: _fromStatus(results[Permission.notification]!),
    );
  }

  /// Request only location
  Future<void> requestLocation() async {
    final result = await Permission.locationWhenInUse.request();
    state = state.copyWith(location: _fromStatus(result));
  }

  /// Request only notification
  Future<void> requestNotification() async {
    final result = await Permission.notification.request();
    state = state.copyWith(notification: _fromStatus(result));
  }

  /// Open app settings for permanently denied permissions
  Future<void> openSettings() => openAppSettings();
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>(
  (ref) => PermissionNotifier(),
);
