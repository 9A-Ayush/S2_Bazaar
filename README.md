# S2 Bazaar

**Quality bhi, Bachat bhi** — A full-featured Flutter e-commerce app for groceries, FMCG, clothing, sarees, and utensils. Built with Flutter + Supabase + Riverpod.

---

## Tech Stack

## 🚀 Tech Stack

| Category            | Stack |
|--------------------|------|
| 🎨 Frontend        | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) |
| 🗄 Backend         | ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white) |
| 🔐 Auth            | ![OTP](https://img.shields.io/badge/Auth-Phone%20OTP-orange?style=for-the-badge&logo=phone) ![Google](https://img.shields.io/badge/Auth-Google%20Sign--In-red?style=for-the-badge&logo=google) |
| 🗺 Maps & Location | ![Google Maps](https://img.shields.io/badge/Google%20Maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white) |
| 🔤 Fonts           | ![Google Fonts](https://img.shields.io/badge/Google%20Fonts-4285F4?style=for-the-badge&logo=google&logoColor=white) |
| 🌐 Localization    | ![i18n](https://img.shields.io/badge/i18n-English%20%7C%20हिन्दी-blueviolet?style=for-the-badge) |
---

## Project Structure

```
s2_bazaar/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_router.dart
│   │   │   └── supabase_config.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   └── deep_link_handler.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── widgets/
│   │       ├── bottom_nav.dart
│   │       └── common_widgets.dart
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/screens/
│   │   │       ├── login_screen.dart
│   │   │       └── otp_screen.dart
│   │   ├── cart/
│   │   │   ├── data/
│   │   │   │   ├── cart_repository.dart
│   │   │   │   └── coupon_repository.dart
│   │   │   └── presentation/screens/
│   │   │       └── cart_screen.dart
│   │   ├── category/
│   │   │   └── presentation/screens/
│   │   │       └── category_screen.dart
│   │   ├── checkout/
│   │   │   ├── data/
│   │   │   │   └── service_area_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── service_area_provider.dart
│   │   │   └── presentation/screens/
│   │   │       └── checkout_screen.dart
│   │   ├── home/
│   │   │   └── presentation/screens/
│   │   │       ├── home_screen.dart
│   │   │       ├── main_shell.dart
│   │   │       └── product_detail_screen.dart
│   │   ├── map/
│   │   │   └── presentation/screens/
│   │   │       └── map_screen.dart
│   │   ├── notifications/
│   │   │   └── presentation/screens/
│   │   │       └── notifications_screen.dart
│   │   ├── onboarding/
│   │   │   └── presentation/screens/
│   │   │       └── onboarding_screen.dart
│   │   ├── orders/
│   │   │   └── presentation/screens/
│   │   │       ├── order_history_screen.dart
│   │   │       └── order_detail_screen.dart
│   │   ├── out_of_service/
│   │   │   └── presentation/screens/
│   │   │       └── out_of_service_screen.dart
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   │   └── profile_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── profile_providers.dart
│   │   │   └── presentation/screens/
│   │   │       ├── profile_screen.dart
│   │   │       ├── edit_profile_screen.dart
│   │   │       ├── saved_addresses_screen.dart
│   │   │       ├── payments_screen.dart
│   │   │       └── settings_screen.dart
│   │   ├── splash/
│   │   │   └── presentation/screens/
│   │   │       └── splash_screen.dart
│   │   └── tracking/
│   │       └── presentation/screens/
│   │           └── order_tracking_screen.dart
│   │   ├── wishlist/
│   │   │   ├── data/
│   │   │   │   └── wishlist_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── wishlist_provider.dart
│   │   │   └── presentation/screens/
│   │   │       └── wishlist_screen.dart
│   ├── l10n/
│   │   ├── app_en.arb
│   │   ├── app_hi.arb
│   │   ├── app_localizations.dart
│   │   ├── app_localizations_en.dart
│   │   └── app_localizations_hi.dart
│   ├── models/
│   │   └── app_models.dart
│   └── providers/
│       ├── app_providers.dart
│       ├── auth_provider.dart
│       ├── locale_provider.dart
│       ├── location_provider.dart
│       └── permission_provider.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── lottie/
├── l10n.yaml
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Development Log

### 25 March 2026 — Project Kickoff

- Initialized Flutter project `s2_bazaar`
- Set up Supabase project and configured `SupabaseConfig` with URL and anon key
- Added core dependencies: `flutter_riverpod`, `go_router`, `supabase_flutter`, `google_fonts`, `cached_network_image`, `geolocator`, `image_picker`, `intl`, `shared_preferences`
- Created base folder structure: `lib/core/`, `lib/features/`, `lib/models/`, `lib/providers/`
- Built `AppTheme` with full design token system — `AppColors`, `AppRadius`, `AppSpacing`, `AppTextStyles`, `AppShadows`
- Configured Material 3 theme with custom `AppBar`, `ElevatedButton`, and `InputDecoration` styles
- Set up `main.dart` with Supabase initialization, PKCE auth flow, and portrait-only orientation lock

---

### 26 March 2026 — Auth & Navigation Foundation

- Built `AuthService` with phone OTP login (`signInWithOtp`) and OTP verification (`verifyOTP`)
- Added Google OAuth support via `signInWithOAuth` with deep link redirect
- Created `authStateProvider`, `sessionProvider`, `currentUserProvider` using Riverpod streams
- Built `GoRouter` setup with 20+ named routes, auth redirect guards, and `GoRouterRefreshStream`
- Implemented custom `_slideTransition` and `_fadeTransition` page transitions
- Created `SplashScreen` with app logo and auto-navigation logic
- Built `OnboardingScreen` for first-time users
- Built `LoginScreen` (phone input) and `OtpScreen` (6-digit OTP entry)
- Added `DeepLinkHandler` service using `app_links` for OAuth callback and deep link routing

---

### 27 March 2026 — Core Data Models & Home Screen

- Defined all app data models in `lib/models/app_models.dart`:
  - `ProductModel` — price, original price, discount, unit, badge, rating, stock
  - `CategoryModel` + `SubCategoryModel` — emoji, bg/text color, product count
  - `CartItemModel` — product + quantity, total price
  - `CouponModel` — percentage/fixed discount, min order, max cap, per-user limits
  - `OrderModel` + `OrderStatus` enum — full order lifecycle
  - `AddressModel` — label, full address, default flag
  - `NotificationModel` + `NotifType` enum
  - `UserModel` — profile with avatar, DOB, gender
  - `PaymentMethodModel` — UPI, Card, NetBanking
- Built `HomeScreen` with category grid, featured products horizontal list, and search bar
- Created `MainShell` with bottom navigation (Home, Categories, Cart, Profile)
- Added `bottomNavIndexProvider` for tab state
- Set up `categoriesProvider`, `featuredProductsProvider` pulling live data from Supabase
- Added `MockData` class with 5 categories, 40+ subcategories, sample products, orders, and notifications as fallback

---

### 28 March 2026 — Categories, Product Detail & Cart

- Built `CategoryScreen` with subcategory chips and product grid filtered by category
- Added `productsByCategoryProvider` and `productProvider` (family providers)
- Built `ProductDetailScreen` with image, price, discount badge, rating, description, and add-to-cart
- Created `CartRepository` with full CRUD: fetch (with product join), add/increment, decrement, delete, clear
- Built `CartNotifier` with optimistic updates — UI updates instantly, reverts on DB failure
- Implemented `cartProvider`, `cartItemsProvider`, `cartItemCountProvider`, `cartSubtotalProvider`, `cartTotalProvider`
- Built `CartScreen` with swipe-to-delete, quantity controls, price summary, and empty state
- Added delivery fee (₹30) and auto-discount (₹50 off orders above ₹200) logic

---

### 29 March 2026 — Checkout, Coupons & Location Services

- Built `CouponRepository` with `fetchActiveCoupons` and `validate` (checks min order, global limit, per-user limit)
- Added `appliedCouponProvider`, `couponDiscountProvider`, `activeCouponsProvider`
- Built coupon entry sheet in cart — apply/remove coupon with validation error messages
- Created `LocationNotifier` with Haversine distance formula, 7km service radius from store (Gopalganj, Bihar)
- Built `ServiceAreaRepository` using Supabase RPC `check_service_area` for server-side distance check
- Created `ServiceAreaNotifier` supporting GPS check, address-based check, and manual coordinates
- Built `CheckoutScreen` — address selection, service area validation gate, payment method picker, order summary
- Built `OutOfServiceScreen` shown when user is outside delivery range
- Added location check flow in router redirect — routes to `outOfService` if `LocationStatus.outOfRange`

---

### 30 March 2026 — Profile, Addresses & Notifications

- Built `ProfileRepository` with full Supabase integration:
  - Profile fetch/upsert with email sync from auth
  - Avatar upload to Supabase Storage (`avatars` bucket) with auto-bucket creation fallback
  - Address CRUD with `trg_single_default_address` trigger support
  - Payment method add/delete
  - Order history fetch with active order count
  - Notification fetch, mark-read, mark-all-read
- Created `profileProvider`, `addressesProvider`, `paymentMethodsProvider`, `ordersProvider`, `notificationsProvider` — all `StateNotifierProvider` with loading/error states
- Built `ProfileScreen` — avatar, name, active order badge, quick links
- Built `EditProfileScreen` — name, phone, avatar picker (camera/gallery), DOB picker, gender selector
- Built `SavedAddressesScreen` — list addresses, set default, delete, add new
- Built `PaymentsScreen` — saved UPI/card/netbanking methods, add/delete
- Built `NotificationsScreen` — grouped notifications with read/unread state, mark all read
- Built `SettingsScreen` — app preferences and sign out

---

### 31 March 2026 — Order Tracking & Map

- Built `OrderHistoryScreen` — list all past orders with status pills, order number, total, date
- Built `OrderTrackingScreen` — step-by-step order status timeline (Pending → Confirmed → Preparing → Out for Delivery → Delivered)
- Added `activeOrderCountProvider` for profile badge
- Built `MapScreen` using `google_maps_flutter` — location picker with draggable marker, confirm location button
- Wired map screen into address flow for coordinate-based service area check
- Added `searchQueryProvider` and `searchResultsProvider` with Supabase `ilike` query for live product search
- Built common widget library in `lib/core/widgets/common_widgets.dart`:
  - `S2AppBar`, `S2IconButton`, `PrimaryButton` (with loading + subtitle variant)
  - `S2SearchBar`, `FilterChipRow`, `QuantityControl`, `AddToCartButton`
  - `DiscountBadge`, `VegIndicator`, `StatusPill`, `EmptyState`, `ShimmerBox`

---

### 1 April 2026 — Polish, Assets, Hindi Localization, Wishlist & Order Detail

- Configured `flutter_launcher_icons` with custom `s2Badge.png` app icon for Android and iOS
- Added font assets: Plus Jakarta Sans (400–800 weight) and Inter via Google Fonts
- Added `assets/images/`, `assets/icons/`, `assets/lottie/` directories
- Added `shimmer` loading skeletons across product grids and cart
- Added `lottie` animations for empty states and order success
- Added Hindi (हिन्दी) language support using `flutter_localizations` and `intl`
  - Created `l10n.yaml` config with ARB template path
  - Added `app_en.arb` and `app_hi.arb` ARB files for English and Hindi strings
  - Wired `localizationsDelegates` and `supportedLocales` in `MaterialApp.router`
  - Added language toggle in `SettingsScreen` — users can switch between English and Hindi
- Built full **Wishlist** feature:
  - `WishlistRepository` — `fetchWishlist` (with product join), `fetchWishlistIds`, `add`, `remove`
  - `WishlistNotifier` — optimistic toggle (add/remove with auto-revert on failure)
  - `WishlistProductsNotifier` — full product list for wishlist screen with `removeLocally`
  - `WishlistScreen` — 2-column product grid, heart icon to remove, add-to-cart, empty state
  - Heart icon state driven by `wishlistProvider` (Set\<String\> of product IDs)
- Built `OrderDetailScreen`:
  - Shows order number, status pill, date, payment method
  - Lists all order items with unit price, quantity, line total
  - Total paid summary card
  - "Track Order" button for active orders (links to `OrderTrackingScreen`)
  - "Cancel Order" button for pending orders with confirmation dialog
  - `cancelOrder` wired to `OrdersNotifier`
  - Color-coded status pills per order state
- Fixed PKCE deep link collision — cleared manual token exchange from `handleDeepLinkCallback` to let Supabase handle it internally
- Locked text scale factor between 0.85–1.2 in `MaterialApp.router` builder for consistent UI across devices
- Wired `permission_handler` for location permission flow on Android/iOS
- Moved Supabase keys out of `supabase_config.dart` to `--dart-define-from-file=.env`
- Added `supabase_config.dart` and `android/local.properties` to `.gitignore`
- Fixed `build.gradle.kts` — added `import java.util.Properties` for Kotlin DSL compatibility
- Final route audit — verified all 20+ routes, redirect guards, and shell route tabs work correctly
- Cleaned up analysis warnings, removed unused imports

---

## Features

- Phone OTP + Google OAuth login
- Location-based service area check (7km radius, Gopalganj Bihar)
- Product catalog with categories, subcategories, search
- Shopping cart with optimistic updates and persistence
- Coupon system with validation and per-user usage tracking
- Checkout with address management and payment selection
- Order history, order detail view, and real-time status tracking
- Order cancellation from detail screen
- Wishlist with optimistic toggle and heart icon state
- User profile with avatar upload
- Push notifications with read/unread state
- Map-based address picker
- English & Hindi language support

## Getting Started

```bash
flutter pub get
flutter run
```

> Make sure to add your Supabase URL and anon key in `lib/core/constants/supabase_config.dart`.

---

## 📫 Let's Connect  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](http://www.linkedin.com/in/ayush-kumar-849a1324b)  
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/9A-Ayush)  
[![Instagram](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://www.instagram.com/ayush_ix_xi)  
[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://canary.discord.com/channels/@me)
[![X](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/ayush_bhai4590?t=HEv_7HYwU_uCIO_8POGwZg&s=09)  
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:wemayush@gmail.com)  


---

## ☕ Support My Work  

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/9a.ayush)
 

_"Code. Secure. Innovate."_  
