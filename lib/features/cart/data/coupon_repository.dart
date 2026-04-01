import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';

enum CouponValidationError {
  notFound,
  expired,
  minOrderNotMet,
  usageLimitReached,
  perUserLimitReached,
}

class CouponValidationResult {
  final CouponModel? coupon;
  final CouponValidationError? error;

  const CouponValidationResult.success(this.coupon) : error = null;
  const CouponValidationResult.failure(this.error) : coupon = null;

  bool get isValid => coupon != null;
}

class CouponRepository {
  final SupabaseClient _client;
  CouponRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all publicly visible active coupons.
  Future<List<CouponModel>> fetchActiveCoupons() async {
    final rows = await _client
        .from('coupons')
        .select()
        .eq('is_active', true)
        .order('created_at');
    return (rows as List).map((e) => CouponModel.fromJson(e)).toList();
  }

  /// Validate a coupon code against the current subtotal and user usage.
  Future<CouponValidationResult> validate(
      String code, double subtotal) async {
    // Fetch coupon (RLS already filters inactive/expired)
    final rows = await _client
        .from('coupons')
        .select()
        .eq('code', code.toUpperCase().trim())
        .eq('is_active', true);

    if ((rows as List).isEmpty) {
      return const CouponValidationResult.failure(
          CouponValidationError.notFound);
    }

    final coupon = CouponModel.fromJson(rows.first);

    // Min order check
    if (subtotal < coupon.minOrderAmount) {
      return const CouponValidationResult.failure(
          CouponValidationError.minOrderNotMet);
    }

    // Global usage limit
    if (coupon.maxUses != null && coupon.usedCount >= coupon.maxUses!) {
      return const CouponValidationResult.failure(
          CouponValidationError.usageLimitReached);
    }

    // Per-user usage limit
    final usageRows = await _client
        .from('coupon_usages')
        .select('id')
        .eq('coupon_id', coupon.id)
        .eq('user_id', _uid);

    if ((usageRows as List).length >= coupon.perUserLimit) {
      return const CouponValidationResult.failure(
          CouponValidationError.perUserLimitReached);
    }

    return CouponValidationResult.success(coupon);
  }
}
