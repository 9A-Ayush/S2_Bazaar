import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';

class WishlistRepository {
  final SupabaseClient _client;
  WishlistRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  Future<List<ProductModel>> fetchWishlist() async {
    final data = await _client
        .from('wishlists')
        .select('*, products(*)')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ProductModel.fromJson(e['products'] as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> fetchWishlistIds() async {
    final data = await _client
        .from('wishlists')
        .select('product_id')
        .eq('user_id', _uid);
    return (data as List).map((e) => e['product_id'] as String).toSet();
  }

  Future<void> add(String productId) async {
    await _client.from('wishlists').insert({
      'user_id': _uid,
      'product_id': productId,
    });
  }

  Future<void> remove(String productId) async {
    await _client
        .from('wishlists')
        .delete()
        .eq('user_id', _uid)
        .eq('product_id', productId);
  }
}
