import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  // ─── Profile ──────────────────────────────────────────────────────────────
  Future<UserModel?> fetchProfile() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', _uid)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<UserModel> upsertProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final payload = <String, dynamic>{
      'id': _uid,
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (phone.isNotEmpty) payload['phone'] = phone;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    // Sync email from auth into profiles table
    final authEmail = _client.auth.currentUser?.email;
    if (authEmail != null && authEmail.isNotEmpty) payload['email'] = authEmail;
    if (dateOfBirth != null) {
      payload['date_of_birth'] =
          '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
    }
    if (gender != null) payload['gender'] = gender;

    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', _uid)
        .maybeSingle();

    Map<String, dynamic> data;
    if (existing != null) {
      data = await _client
          .from('profiles')
          .update(payload)
          .eq('id', _uid)
          .select()
          .single();
    } else {
      data = await _client
          .from('profiles')
          .insert(payload)
          .select()
          .single();
    }
    return UserModel.fromJson(data);
  }

  Future<String> uploadAvatar(File file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    return _uploadAvatarBytes(bytes, ext);
  }

  Future<String> uploadAvatarBytes(Uint8List bytes, String ext) =>
      _uploadAvatarBytes(bytes, ext);

  Future<String> _uploadAvatarBytes(Uint8List bytes, String ext) async {
    final path = '$_uid/avatar.$ext';
    try {
      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      if (e.statusCode == '404') {
        await _client.storage
            .createBucket('avatars', const BucketOptions(public: true));
        await _client.storage.from('avatars').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        rethrow;
      }
    }
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  // ─── Addresses ────────────────────────────────────────────────────────────
  Future<List<AddressModel>> fetchAddresses() async {
    final data = await _client
        .from('addresses')
        .select()
        .eq('user_id', _uid)
        .order('is_default', ascending: false)
        .order('created_at');
    return (data as List).map((e) => AddressModel.fromJson(e)).toList();
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final data = await _client
        .from('addresses')
        .insert({...address.toJson(), 'user_id': _uid})
        .select()
        .single();
    return AddressModel.fromJson(data);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    final data = await _client
        .from('addresses')
        .update(address.toJson())
        .eq('id', address.id)
        .select()
        .single();
    return AddressModel.fromJson(data);
  }

  Future<void> deleteAddress(String id) async {
    await _client.from('addresses').delete().eq('id', id);
  }

  Future<void> setDefaultAddress(String id) async {
    // The schema has a trigger (trg_single_default_address) that auto-clears
    // other defaults when one is set — just update the target row
    await _client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', id);
  }

  // ─── Payment Methods ──────────────────────────────────────────────────────
  Future<List<PaymentMethodModel>> fetchPaymentMethods() async {
    final data = await _client
        .from('payment_methods')
        .select()
        .eq('user_id', _uid)
        .order('is_default', ascending: false)
        .order('created_at');
    return (data as List).map((e) => PaymentMethodModel.fromJson(e)).toList();
  }

  Future<PaymentMethodModel> addPaymentMethod(PaymentMethodModel method) async {
    final data = await _client
        .from('payment_methods')
        .insert({...method.toJson(), 'user_id': _uid})
        .select()
        .single();
    return PaymentMethodModel.fromJson(data);
  }

  Future<void> deletePaymentMethod(String id) async {
    await _client.from('payment_methods').delete().eq('id', id);
  }

  // ─── Orders ───────────────────────────────────────────────────────────────
  Future<List<OrderModel>> fetchOrders() async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return (data as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  Future<int> fetchActiveOrderCount() async {
    final data = await _client
        .from('orders')
        .select('id')
        .eq('user_id', _uid)
        .inFilter('status', ['pending', 'confirmed', 'preparing', 'out_for_delivery']);
    return (data as List).length;
  }

  /// Creates an order + order_items in a single transaction-like sequence.
  /// Returns the created [OrderModel].
  Future<OrderModel> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String addressId,
    required String paymentMethod,
  }) async {
    // 1. Insert order row
    final orderRow = await _client
        .from('orders')
        .insert({
          'user_id': _uid,
          'total_amount': totalAmount,
          'status': 'pending',
          'address_id': addressId,
          'payment_method': paymentMethod,
        })
        .select()
        .single();

    final orderId = orderRow['id'] as String;

    // 2. Insert order_items
    await _client.from('order_items').insert(
      items
          .map((item) => {
                'order_id': orderId,
                'product_id': item.product.id,
                'quantity': item.quantity,
                'price_at_time': item.product.price,
              })
          .toList(),
    );

    return OrderModel.fromJson(orderRow);
  }

  Future<void> cancelOrder(String orderId) async {
    await _client
        .from('orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId)
        .eq('user_id', _uid);
  }

  // ─── Notifications ────────────────────────────────────────────────────────
  Future<List<NotificationModel>> fetchNotifications() async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
  }
}
