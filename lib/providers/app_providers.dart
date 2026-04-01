import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/cart/data/coupon_repository.dart';

final supabase = Supabase.instance.client;

// ─── Cart Repository ──────────────────────────────────────────────────────────
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(Supabase.instance.client);
});

// ─── Coupon Repository & State ────────────────────────────────────────────────
final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository(Supabase.instance.client);
});

/// Holds the currently applied coupon (null = none applied).
final appliedCouponProvider = StateProvider<CouponModel?>((ref) => null);

/// Fetch all active coupons for display in the sheet.
final activeCouponsProvider = FutureProvider<List<CouponModel>>((ref) async {
  return ref.read(couponRepositoryProvider).fetchActiveCoupons();
});

// ─── Cart State ───────────────────────────────────────────────────────────────
class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  final CartRepository _repo;

  CartNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.fetchItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      // On load failure default to empty so UI isn't stuck on spinner
      state = AsyncValue.data(const []);
    }
  }

  List<CartItemModel> get _items => state.valueOrNull ?? [];

  Future<void> addItem(ProductModel product) async {
    final idx = _items.indexWhere((e) => e.product.id == product.id);
    final currentQty = idx >= 0 ? _items[idx].quantity : 0;

    // Optimistic update immediately
    if (idx >= 0) {
      final updated = List<CartItemModel>.from(_items);
      updated[idx] = updated[idx].copyWith(quantity: currentQty + 1);
      state = AsyncValue.data(updated);
    } else {
      state = AsyncValue.data([..._items, CartItemModel(product: product)]);
    }

    // Persist to DB (fire and forget — optimistic state already applied)
    try {
      await _repo.addItem(product, currentQty: currentQty);
    } catch (_) {
      // Revert optimistic update on failure
      await _load();
    }
  }

  Future<void> removeItem(String productId) async {
    final idx = _items.indexWhere((e) => e.product.id == productId);
    if (idx < 0) return;
    final item = _items[idx];
    final currentQty = item.quantity;

    // Optimistic update
    if (currentQty <= 1) {
      state = AsyncValue.data(
          _items.where((e) => e.product.id != productId).toList());
    } else {
      final updated = List<CartItemModel>.from(_items);
      updated[idx] = item.copyWith(quantity: currentQty - 1);
      state = AsyncValue.data(updated);
    }

    try {
      await _repo.decrementItem(productId, currentQty: currentQty);
    } catch (_) {
      await _load();
    }
  }

  Future<void> deleteItem(String productId) async {
    state = AsyncValue.data(
        _items.where((e) => e.product.id != productId).toList());
    try {
      await _repo.deleteItem(productId);
    } catch (_) {
      await _load();
    }
  }

  Future<void> clearCart() async {
    state = const AsyncValue.data([]);
    try {
      await _repo.clearCart();
    } catch (_) {
      await _load();
    }
  }

  double get subtotal => _items.fold(0, (s, i) => s + i.totalPrice);
  double get deliveryFee => _items.isEmpty ? 0 : 30;
  double get discount => subtotal > 200 ? 50 : 0;
  double get total => subtotal + deliveryFee - discount;
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);
  int quantityOf(String productId) {
    final idx = _items.indexWhere((e) => e.product.id == productId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>(
  (ref) => CartNotifier(ref.read(cartRepositoryProvider)),
);

// Derived providers — unwrap AsyncValue safely
final cartItemsProvider = Provider<List<CartItemModel>>((ref) {
  return ref.watch(cartProvider).valueOrNull ?? [];
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsProvider);
  return items.fold(0, (s, i) => s + i.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).subtotal;
});

/// Discount from applied coupon (0 if none).
final couponDiscountProvider = Provider<double>((ref) {
  final coupon = ref.watch(appliedCouponProvider);
  final subtotal = ref.watch(cartSubtotalProvider);
  return coupon?.discountFor(subtotal) ?? 0;
});

final cartTotalProvider = Provider<double>((ref) {
  final notifier = ref.read(cartProvider.notifier);
  ref.watch(cartProvider);
  final couponDiscount = ref.watch(couponDiscountProvider);
  return (notifier.subtotal + notifier.deliveryFee - notifier.discount - couponDiscount)
      .clamp(0, double.infinity);
});

// ─── Supabase Providers ───────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final response = await supabase
      .from('categories')
      .select('*, sub_categories(*)')
      .eq('is_active', true)
      .order('sort_order');
  return (response as List).map((e) => CategoryModel.fromJson(e)).toList();
});

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final response = await supabase
      .from('products')
      .select()
      .eq('is_active', true)
      .eq('is_featured', true)
      .order('created_at', ascending: false);
  return (response as List).map((e) => ProductModel.fromJson(e)).toList();
});

final productsByCategoryProvider = FutureProvider.family<List<ProductModel>, String>((ref, categoryId) async {
  final response = await supabase
      .from('products')
      .select()
      .eq('is_active', true)
      .eq('category_id', categoryId)
      .order('created_at', ascending: false);
  return (response as List).map((e) => ProductModel.fromJson(e)).toList();
});

final productProvider = FutureProvider.family<ProductModel, String>((ref, productId) async {
  final response = await supabase
      .from('products')
      .select()
      .eq('id', productId)
      .single();
  return ProductModel.fromJson(response);
});

// ─── Mock Data ────────────────────────────────────────────────────────────────
class MockData {
  static final List<CategoryModel> categories = [
    const CategoryModel(
      id: 'groceries',
      name: 'Groceries',
      emoji: '🥦',
      color: 0xFFE3F2FD,
      textColor: 0xFF1565C0,
      subcategories: [
        SubCategoryModel(id: 'fruits', name: 'Fruits & Veg', emoji: '🥦', color: 0xFFE3F2FD, count: 24),
        SubCategoryModel(id: 'dairy', name: 'Dairy & Eggs', emoji: '🥛', color: 0xFFFFF8E1, count: 18),
        SubCategoryModel(id: 'grains', name: 'Rice & Dal', emoji: '🌾', color: 0xFFE8F5E9, count: 32),
        SubCategoryModel(id: 'oil', name: 'Oil & Ghee', emoji: '🫙', color: 0xFFFFF3E0, count: 15),
        SubCategoryModel(id: 'spices', name: 'Spices', emoji: '🌶️', color: 0xFFFCE4EC, count: 42),
        SubCategoryModel(id: 'bread', name: 'Bread & Bakery', emoji: '🍞', color: 0xFFEDE7F6, count: 12),
        SubCategoryModel(id: 'packaged', name: 'Packaged Food', emoji: '📦', color: 0xFFE0F7FA, count: 38),
        SubCategoryModel(id: 'frozen', name: 'Frozen Food', emoji: '🧊', color: 0xFFE8EAF6, count: 9),
      ],
    ),
    const CategoryModel(
      id: 'fmcg',
      name: 'FMCG',
      emoji: '🧴',
      color: 0xFFFFF3E0,
      textColor: 0xFFE65100,
      subcategories: [
        SubCategoryModel(id: 'personal', name: 'Personal Care', emoji: '🧴', color: 0xFFFCE4EC, count: 45),
        SubCategoryModel(id: 'oral', name: 'Oral Care', emoji: '🪥', color: 0xFFE8F5E9, count: 18),
        SubCategoryModel(id: 'cleaning', name: 'Home Cleaning', emoji: '🧹', color: 0xFFE3F2FD, count: 22),
        SubCategoryModel(id: 'baby', name: 'Baby Care', emoji: '🍼', color: 0xFFFFF8E1, count: 30),
        SubCategoryModel(id: 'health', name: 'Health & Wellness', emoji: '💊', color: 0xFFF3E5F5, count: 25),
        SubCategoryModel(id: 'hygiene', name: 'Paper & Hygiene', emoji: '🧻', color: 0xFFE0F7FA, count: 15),
      ],
    ),
    const CategoryModel(
      id: 'clothing',
      name: 'Clothes',
      emoji: '👕',
      color: 0xFFFCE4EC,
      textColor: 0xFF880E4F,
      subcategories: [
        SubCategoryModel(id: 'men', name: 'Men', emoji: '👔', color: 0xFFE3F2FD, count: 80),
        SubCategoryModel(id: 'women', name: 'Women', emoji: '👗', color: 0xFFFCE4EC, count: 120),
        SubCategoryModel(id: 'kids', name: 'Kids', emoji: '🧒', color: 0xFFE8F5E9, count: 60),
      ],
    ),
    const CategoryModel(
      id: 'sarees',
      name: 'Sarees',
      emoji: '🥻',
      color: 0xFFF3E5F5,
      textColor: 0xFF6A1B9A,
      subcategories: [
        SubCategoryModel(id: 'cotton', name: 'Cotton Sarees', emoji: '🌸', color: 0xFFFCE4EC, count: 35),
        SubCategoryModel(id: 'silk', name: 'Silk Sarees', emoji: '✨', color: 0xFFF3E5F5, count: 28),
        SubCategoryModel(id: 'designer', name: 'Designer Sarees', emoji: '💎', color: 0xFFEDE7F6, count: 18),
        SubCategoryModel(id: 'daily', name: 'Daily Wear', emoji: '🎀', color: 0xFFFFF3E0, count: 45),
      ],
    ),
    const CategoryModel(
      id: 'utensils',
      name: 'Utensils',
      emoji: '🍳',
      color: 0xFFE8F5E9,
      textColor: 0xFF2E7D32,
      subcategories: [
        SubCategoryModel(id: 'cookware', name: 'Cookware', emoji: '🥘', color: 0xFFE8F5E9, count: 22),
        SubCategoryModel(id: 'pressure', name: 'Pressure Cookers', emoji: '⚗️', color: 0xFFFFF8E1, count: 10),
        SubCategoryModel(id: 'storage', name: 'Storage', emoji: '📦', color: 0xFFE3F2FD, count: 30),
        SubCategoryModel(id: 'dinnersets', name: 'Dinner Sets', emoji: '🍽️', color: 0xFFFCE4EC, count: 15),
        SubCategoryModel(id: 'tools', name: 'Kitchen Tools', emoji: '🔪', color: 0xFFF3E5F5, count: 40),
        SubCategoryModel(id: 'stove', name: 'Gas Stove', emoji: '🔥', color: 0xFFE0F7FA, count: 8),
      ],
    ),
  ];

  static final List<ProductModel> featuredProducts = [
    const ProductModel(
      id: 'p1',
      name: 'Fresh Tomatoes',
      imageUrl: 'https://images.unsplash.com/photo-1561136594-7f68081a8519?w=400',
      price: 49,
      originalPrice: 65,
      discountPercent: 25,
      unit: '1 kg',
      categoryId: 'groceries',
      badge: '20% OFF',
      rating: 4.7,
      reviewCount: 243,
      description: 'Farm-fresh tomatoes sourced directly from local farmers. Rich in vitamins A & C.',
    ),
    const ProductModel(
      id: 'p2',
      name: 'Aashirvaad Atta 5kg',
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
      price: 289,
      originalPrice: 320,
      unit: '5 kg',
      categoryId: 'fmcg',
      badge: 'BESTSELLER',
      rating: 4.8,
      reviewCount: 1240,
    ),
    const ProductModel(
      id: 'p3',
      name: 'Fresh Apples',
      imageUrl: 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=400',
      price: 89,
      unit: '1 kg',
      categoryId: 'groceries',
      rating: 4.5,
    ),
    const ProductModel(
      id: 'p4',
      name: 'Fresh Spinach',
      imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
      price: 35,
      unit: '250 g',
      categoryId: 'groceries',
      rating: 4.3,
    ),
  ];

  static final List<OrderModel> orders = [
    OrderModel(
      id: 'S2-20483',
      items: [],
      totalAmount: 565,
      status: OrderStatus.outForDelivery,
      createdAt: DateTime.now(),
      deliveryAddress: const AddressModel(
        id: 'a1',
        label: 'Home',
        fullName: 'Ayush Kumar',
        phone: '9876543210',
        line1: '42, Gandhi Nagar',
        line2: 'Near City Mall',
        city: 'Patna',
        state: 'Bihar',
        pincode: '800001',
        isDefault: true,
      ),
      paymentMethod: 'upi',
    ),
    OrderModel(
      id: 'S2-20471',
      items: [],
      totalAmount: 338,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      deliveryAddress: const AddressModel(
        id: 'a1',
        label: 'Home',
        fullName: 'Ayush Kumar',
        phone: '9876543210',
        line1: '42, Gandhi Nagar',
        city: 'Patna',
        state: 'Bihar',
        pincode: '800001',
      ),
      paymentMethod: 'cod',
    ),
    OrderModel(
      id: 'S2-20458',
      items: [],
      totalAmount: 920,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      deliveryAddress: const AddressModel(
        id: 'a1',
        label: 'Home',
        fullName: 'Ayush Kumar',
        phone: '9876543210',
        line1: '42, Gandhi Nagar',
        city: 'Patna',
        state: 'Bihar',
        pincode: '800001',
      ),
      paymentMethod: 'card',
    ),
  ];

  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n1',
      title: 'Order Out for Delivery!',
      message: 'Your order #S2-20483 is on the way. Expected in 15 mins.',
      type: NotifType.order,
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n2',
      title: 'Order Confirmed',
      message: "Your order #S2-20483 has been confirmed. We're preparing it now.",
      type: NotifType.order,
      time: DateTime.now().subtract(const Duration(minutes: 18)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n3',
      title: 'Flat 40% OFF Today Only!',
      message: 'Use code SAVE40 on groceries & FMCG. Hurry, offer ends midnight!',
      type: NotifType.offer,
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n4',
      title: 'Order Delivered',
      message: 'Your order #S2-20471 has been delivered. Hope you liked it!',
      type: NotifType.order,
      time: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n5',
      title: 'Rate Your Order',
      message: 'How was your order #S2-20471? Tap to leave a review.',
      type: NotifType.general,
      time: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
  ];

  static const user = UserModel(
    id: 'u1',
    name: 'Ayush Kumar',
    phone: '+91 98765 43210',
    addresses: [
      AddressModel(
        id: 'a1',
        label: 'Home',
        fullName: 'Ayush Kumar',
        phone: '9876543210',
        line1: '42, Gandhi Nagar',
        line2: 'Near City Mall',
        city: 'Patna',
        state: 'Bihar',
        pincode: '800001',
        isDefault: true,
      ),
    ],
  );
}

// ─── Bottom Nav State ─────────────────────────────────────────────────────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ─── Search State ─────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return [];

  final response = await supabase
      .from('products')
      .select()
      .eq('is_active', true)
      .ilike('name', '%$query%');

  return (response as List).map((e) => ProductModel.fromJson(e)).toList();
});

// ─── Selected Payment Method ──────────────────────────────────────────────────
enum PaymentMethod { upi, card, cod }

final paymentMethodProvider = StateProvider<PaymentMethod>(
    (ref) => PaymentMethod.upi);
