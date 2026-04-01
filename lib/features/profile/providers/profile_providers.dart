import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';
import '../data/profile_repository.dart';

// ─── Repository ───────────────────────────────────────────────────────────────
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// ─── Profile ──────────────────────────────────────────────────────────────────
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
  return ProfileNotifier(ref.read(profileRepositoryProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ProfileRepository _repo;
  ProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.fetchProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update({
    required String fullName,
    required String phone,
    XFile? avatarFile,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final current = state.valueOrNull;
    String? avatarUrl;
    if (avatarFile != null) {
      final bytes = await avatarFile.readAsBytes();
      final ext = avatarFile.name.split('.').last.toLowerCase();
      avatarUrl = await _repo.uploadAvatarBytes(bytes, ext);
    }
    final updated = await _repo.upsertProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl ?? current?.avatarUrl,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    state = AsyncValue.data(updated);
  }
}

// ─── Addresses ────────────────────────────────────────────────────────────────
final addressesProvider =
    StateNotifierProvider<AddressesNotifier, AsyncValue<List<AddressModel>>>(
        (ref) {
  return AddressesNotifier(ref.read(profileRepositoryProvider));
});

class AddressesNotifier
    extends StateNotifier<AsyncValue<List<AddressModel>>> {
  final ProfileRepository _repo;
  AddressesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchAddresses();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(AddressModel address) async {
    final added = await _repo.addAddress(address);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, added]);
  }

  Future<void> update(AddressModel address) async {
    final updated = await _repo.updateAddress(address);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((a) => a.id == updated.id ? updated : a).toList());
  }

  Future<void> delete(String id) async {
    await _repo.deleteAddress(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((a) => a.id != id).toList());
  }

  Future<void> setDefault(String id) async {
    await _repo.setDefaultAddress(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((a) => a.copyWith(isDefault: a.id == id)).toList());
  }
}

// ─── Payment Methods ──────────────────────────────────────────────────────────
final paymentMethodsProvider = StateNotifierProvider<PaymentMethodsNotifier,
    AsyncValue<List<PaymentMethodModel>>>((ref) {
  return PaymentMethodsNotifier(ref.read(profileRepositoryProvider));
});

class PaymentMethodsNotifier
    extends StateNotifier<AsyncValue<List<PaymentMethodModel>>> {
  final ProfileRepository _repo;
  PaymentMethodsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchPaymentMethods();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(PaymentMethodModel method) async {
    final added = await _repo.addPaymentMethod(method);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, added]);
  }

  Future<void> delete(String id) async {
    await _repo.deletePaymentMethod(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((m) => m.id != id).toList());
  }
}

// ─── Orders ───────────────────────────────────────────────────────────────────
final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrdersNotifier(ref.read(profileRepositoryProvider));
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final ProfileRepository _repo;
  OrdersNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchOrders();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activeOrderCountProvider = FutureProvider<int>((ref) async {
  return ref.read(profileRepositoryProvider).fetchActiveOrderCount();
});

// ─── Notifications ────────────────────────────────────────────────────────────
final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier(ref.read(profileRepositoryProvider));
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ProfileRepository _repo;
  NotificationsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.fetchNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    await _repo.markNotificationRead(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList());
  }

  Future<void> markAllRead() async {
    await _repo.markAllNotificationsRead();
    final current = state.valueOrNull ?? [];
    state =
        AsyncValue.data(current.map((n) => n.copyWith(isRead: true)).toList());
  }
}
