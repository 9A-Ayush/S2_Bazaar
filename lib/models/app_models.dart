// ─── Product Model ────────────────────────────────────────────────────────────
class ProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final double? discountPercent;
  final String unit;
  final String categoryId;
  final String? badge;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String? description;

  const ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    required this.unit,
    required this.categoryId,
    this.badge,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.inStock = true,
    this.description,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['thumbnail_url'] as String? ??
          (json['images'] != null && (json['images'] as List).isNotEmpty
              ? json['images'][0]
              : ''),
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      unit: json['unit'] as String? ?? 'piece',
      categoryId: json['category_id'] as String,
      badge: json['badge'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['review_count'] as int? ?? 0,
      inStock: (json['stock_quantity'] as int? ?? 0) > 0,
      description: json['description'] as String?,
    );
  }

  double get discountAmount =>
      originalPrice != null ? originalPrice! - price : 0;
}

// ─── Category Model ───────────────────────────────────────────────────────────
class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final int color; // background color as int
  final int textColor;
  final List<SubCategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.textColor,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int parseColor(String hex) {
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      return int.tryParse(hex, radix: 16) ?? 0xFFFFFFFF;
    }

    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🛍️',
      color: parseColor(json['bg_color'] as String? ?? '#F5F5F5'),
      textColor: parseColor(json['text_color'] as String? ?? '#1A1A1A'),
      subcategories: json['sub_categories'] != null
          ? (json['sub_categories'] as List)
              .map((e) => SubCategoryModel.fromJson(e))
              .toList()
          : const [],
    );
  }
}

class SubCategoryModel {
  final String id;
  final String name;
  final String emoji;
  final int color;
  final int count;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.count = 0,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    int parseColor(String hex) {
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      return int.tryParse(hex, radix: 16) ?? 0xFFFFFFFF;
    }

    return SubCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🛍️',
      color: parseColor(json['bg_color'] as String? ?? '#F5F5F5'),
      count: json['product_count'] as int? ?? 0,
    );
  }
}

// ─── Cart Item Model ──────────────────────────────────────────────────────────
class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['products'] ?? json['product'] ?? {}),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  /// Parse from order_items row (has price_at_time, product_id, and nested products)
  factory CartItemModel.fromOrderItem(Map<String, dynamic> json) {
    final productData = json['products'] as Map<String, dynamic>?;
    final priceAtTime = (json['price_at_time'] as num?)?.toDouble();
    ProductModel product;
    if (productData != null) {
      product = ProductModel.fromJson(productData);
      // Override price with price_at_time if available
      if (priceAtTime != null) {
        product = ProductModel(
          id: product.id,
          name: product.name,
          imageUrl: product.imageUrl,
          price: priceAtTime,
          originalPrice: product.originalPrice,
          unit: product.unit,
          categoryId: product.categoryId,
          badge: product.badge,
          rating: product.rating,
          reviewCount: product.reviewCount,
          inStock: product.inStock,
          description: product.description,
        );
      }
    } else {
      // Fallback: minimal product from order_item data
      product = ProductModel(
        id: json['product_id'] as String? ?? '',
        name: 'Product',
        imageUrl: '',
        price: priceAtTime ?? 0,
        unit: 'piece',
        categoryId: '',
      );
    }
    return CartItemModel(
      product: product,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  double get totalPrice => product.price * quantity;

  CartItemModel copyWith({int? quantity}) => CartItemModel(
    product: product,
    quantity: quantity ?? this.quantity,
  );
}

// ─── Coupon Model ─────────────────────────────────────────────────────────────
class CouponModel {
  final String id;
  final String code;
  final String? description;
  final String type; // 'percentage' | 'fixed'
  final double value;
  final double? maxCap;
  final double minOrderAmount;
  final int? maxUses;
  final int usedCount;
  final int perUserLimit;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.type,
    required this.value,
    this.maxCap,
    required this.minOrderAmount,
    this.maxUses,
    required this.usedCount,
    required this.perUserLimit,
    required this.isActive,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
        id: json['id'] as String,
        code: json['code'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        value: (json['value'] as num).toDouble(),
        maxCap: json['max_cap'] != null ? (json['max_cap'] as num).toDouble() : null,
        minOrderAmount: (json['min_order_amount'] as num).toDouble(),
        maxUses: json['max_uses'] as int?,
        usedCount: json['used_count'] as int? ?? 0,
        perUserLimit: json['per_user_limit'] as int? ?? 1,
        isActive: json['is_active'] as bool? ?? true,
      );

  /// Compute discount amount for a given subtotal.
  double discountFor(double subtotal) {
    if (subtotal < minOrderAmount) return 0;
    if (type == 'fixed') return value;
    // percentage
    final raw = subtotal * value / 100;
    return maxCap != null ? raw.clamp(0, maxCap!) : raw;
  }

  String get label {
    if (type == 'fixed') return '₹${value.toInt()} off';
    final capStr = maxCap != null ? ' (max ₹${maxCap!.toInt()})' : '';
    return '${value.toInt()}% off$capStr';
  }

  String get minOrderLabel =>
      minOrderAmount > 0 ? 'Min order ₹${minOrderAmount.toInt()}' : 'No minimum';
}

// ─── Order Model ─────────────────────────────────────────────────────────────
class OrderModel {
  final String id;
  final String? orderNumber;
  final List<CartItemModel> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final AddressModel? deliveryAddress;
  final String paymentMethod;

  const OrderModel({
    required this.id,
    this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
    required this.paymentMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        items: json['order_items'] != null
            ? (json['order_items'] as List)
                .map((e) => CartItemModel.fromOrderItem(e))
                .toList()
            : const [],
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: _parseStatus(json['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(json['created_at'] as String),
        paymentMethod: json['payment_method'] as String? ?? 'cod',
        orderNumber: json['order_number'] as String?,
      );

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed': return OrderStatus.confirmed;
      case 'preparing': return OrderStatus.preparing;
      case 'out_for_delivery': return OrderStatus.outForDelivery;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.preparing: return 'Preparing';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}

enum OrderStatus { pending, confirmed, preparing, outForDelivery, delivered, cancelled }

// ─── Address Model ────────────────────────────────────────────────────────────
class AddressModel {
  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] as String,
        label: json['label'] as String? ?? 'Home',
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        line1: json['line1'] as String? ?? '',
        line2: json['line2'] as String? ?? '',
        city: json['city'] as String,
        state: json['state'] as String,
        pincode: json['pincode'] as String,
        landmark: json['landmark'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'line1': line1,
        if (line2.isNotEmpty) 'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        'is_default': isDefault,
      };

  AddressModel copyWith({
    String? id,
    String? label,
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
  }) =>
      AddressModel(
        id: id ?? this.id,
        label: label ?? this.label,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
        landmark: landmark ?? this.landmark,
        isDefault: isDefault ?? this.isDefault,
      );

  String get fullAddress {
    final parts = [line1, if (line2.isNotEmpty) line2, city, state, pincode];
    return parts.join(', ');
  }
}

// ─── Notification Model ───────────────────────────────────────────────────────
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotifType type;
  final DateTime time;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        type: _parseType(json['type'] as String? ?? 'general'),
        time: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  static NotifType _parseType(String t) {
    switch (t) {
      case 'order': return NotifType.order;
      case 'offer': return NotifType.offer;
      case 'alert': return NotifType.alert;
      default: return NotifType.general;
    }
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        type: type,
        time: time,
        isRead: isRead ?? this.isRead,
      );
}

enum NotifType { order, offer, alert, general }

// ─── User Model ───────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender; // male, female, other, prefer_not_to_say
  final List<AddressModel> addresses;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.addresses = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.tryParse(json['date_of_birth'] as String)
            : null,
        gender: json['gender'] as String?,
      );

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        addresses: addresses,
      );
}

// ─── Payment Method Model ─────────────────────────────────────────────────────
class PaymentMethodModel {
  final String id;
  final String type; // UPI, Card, NetBanking
  final String label;
  final String details;
  final bool isDefault;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.label,
    required this.details,
    this.isDefault = false,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id: json['id'] as String,
        type: json['type'] as String,
        label: json['label'] as String,
        details: json['details'] as String,
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        'details': details,
        'is_default': isDefault,
      };
}
