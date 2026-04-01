import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';

class CartRepository {
  final SupabaseClient _client;
  CartRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all cart items for the current user, joining product data.
  Future<List<CartItemModel>> fetchItems() async {
    final rows = await _client
        .from('cart_items')
        .select('*, products(*)')
        .eq('user_id', _uid)
        .order('created_at');
    return (rows as List).map((e) => CartItemModel.fromJson(e)).toList();
  }

  /// Add one unit of a product. If already in cart, increments quantity.
  Future<void> addItem(ProductModel product, {int currentQty = 0}) async {
    if (currentQty > 0) {
      // Row exists — just increment
      await _client
          .from('cart_items')
          .update({'quantity': currentQty + 1})
          .eq('user_id', _uid)
          .eq('product_id', product.id);
    } else {
      // New row
      await _client.from('cart_items').insert({
        'user_id': _uid,
        'product_id': product.id,
        'quantity': 1,
      });
    }
  }

  /// Decrement quantity by 1. Deletes row if quantity reaches 0.
  Future<void> decrementItem(String productId, {required int currentQty}) async {
    if (currentQty <= 1) {
      await deleteItem(productId);
    } else {
      await _client
          .from('cart_items')
          .update({'quantity': currentQty - 1})
          .eq('user_id', _uid)
          .eq('product_id', productId);
    }
  }

  /// Hard delete a cart item row.
  Future<void> deleteItem(String productId) async {
    await _client
        .from('cart_items')
        .delete()
        .eq('user_id', _uid)
        .eq('product_id', productId);
  }

  /// Delete all cart items for the user.
  Future<void> clearCart() async {
    await _client.from('cart_items').delete().eq('user_id', _uid);
  }
}
