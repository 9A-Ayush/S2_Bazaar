import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_models.dart';
import '../data/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(Supabase.instance.client);
});

// ─── Wishlist IDs (Set<String>) — drives heart icon state ────────────────────
final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, AsyncValue<Set<String>>>((ref) {
  return WishlistNotifier(ref.read(wishlistRepositoryProvider));
});

class WishlistNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final WishlistRepository _repo;

  WishlistNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final ids = await _repo.fetchWishlistIds();
      state = AsyncValue.data(ids);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isWishlisted(String productId) =>
      state.valueOrNull?.contains(productId) ?? false;

  Future<void> toggle(String productId) async {
    final current = Set<String>.from(state.valueOrNull ?? {});
    if (current.contains(productId)) {
      // Optimistic remove
      current.remove(productId);
      state = AsyncValue.data(current);
      try {
        await _repo.remove(productId);
      } catch (_) {
        // Revert on failure
        current.add(productId);
        state = AsyncValue.data(current);
      }
    } else {
      // Optimistic add
      current.add(productId);
      state = AsyncValue.data(current);
      try {
        await _repo.add(productId);
      } catch (_) {
        // Revert on failure
        current.remove(productId);
        state = AsyncValue.data(current);
      }
    }
  }
}

// ─── Full wishlist products (for wishlist screen) ─────────────────────────────
final wishlistProductsProvider =
    StateNotifierProvider<WishlistProductsNotifier, AsyncValue<List<ProductModel>>>(
        (ref) {
  return WishlistProductsNotifier(ref.read(wishlistRepositoryProvider));
});

class WishlistProductsNotifier
    extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final WishlistRepository _repo;

  WishlistProductsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final products = await _repo.fetchWishlist();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void removeLocally(String productId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.where((p) => p.id != productId).toList());
  }
}
