import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/features/cart/presentation/screens/cart_screen.dart';
import 'package:mix/features/orders/presentation/screens/order_screen.dart';
import 'package:mix/features/products/data/product_repository.dart';
import 'package:mix/features/products/presentation/screens/product_detail_screen.dart';
import 'package:mix/features/profile/presentation/screens/profile_screen.dart';
import 'package:mix/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:mix/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:mix/features/shared/presentation/widgets/active_service_card.dart';
import 'package:mix/features/shared/presentation/widgets/app_shimmer_loader.dart';
import 'package:mix/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/admin_preview_scope.dart';
import 'package:mix/services/firebase_service.dart';

class ProductListScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProductListScreen({super.key, this.showBottomNav = true});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repo = ProductRepository();
  final _firebaseService = FirebaseService();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = 'All';

  bool _matchesSearch(ProductModel product, String query) {
    if (query.isEmpty) return true;

    final q = query.toLowerCase();

    return product.name.toLowerCase().contains(q) ||
        product.description.toLowerCase().contains(q) ||
        product.normalizedCategories.any((c) => c.toLowerCase().contains(q)) ||
        product.variants.any((v) => v.toLowerCase().contains(q));
  }

  bool _matchesCategory(ProductModel product, String category) {
    if (category == 'All') return true;
    return product.hasCategory(category);
  }

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  Future<void> _goToLogin() async {
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  void _openNotificationsPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final user = FirebaseAuth.instance.currentUser;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user == null
                      ? 'Sign in to receive order, ride, delivery, and account notifications.'
                      : 'Push notifications are enabled in the background. In-app notification history screen is not wired yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (user == null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _goToLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC29B40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5EF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9DFC6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Color(0xFFC29B40),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Notification bell is now clickable. Next step is building full notification history UI.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: const Color(0xFF1D1D1F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
    _firebaseService.seedDefaultAppSettings();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);

    final body = SafeArea(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firebaseService.watchUserProfile(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data ?? {};
          final authUser = FirebaseAuth.instance.currentUser;

          final profileDisplayName = (profile['displayName'] ?? '').toString().trim();
          final authDisplayName = (authUser?.displayName ?? '').trim();
          final authEmail = (authUser?.email ?? '').trim();

          final displayName = profileDisplayName.isNotEmpty
              ? profileDisplayName
              : (authDisplayName.isNotEmpty
                  ? authDisplayName
                  : (_isGuest ? 'Guest' : (authEmail.isNotEmpty ? authEmail : 'User')));

          final profilePhotoUrl = (profile['photoUrl'] ?? '').toString().trim();
          final authPhotoUrl = (authUser?.photoURL ?? '').trim();
          final headerPhotoUrl =
              profilePhotoUrl.isNotEmpty ? profilePhotoUrl : authPhotoUrl;

          return StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, categorySnapshot) {
              final dynamicCategories = categorySnapshot.data ?? const <String>[];
              final categories = ['All', ...dynamicCategories];

              if (!categories.contains(_selectedCategory)) {
                _selectedCategory = 'All';
              }

              return StreamBuilder<List<RideModel>>(
                stream: _firebaseService.watchUserRides(),
                builder: (context, rideSnapshot) {
                  final rides = rideSnapshot.data ?? [];

                  final activeServices = rides
                      .where((r) => r.isActive)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return StreamBuilder<List<ProductModel>>(
                    stream: _repo.watchProducts(),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: 6,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (_, __) {
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppShimmerLoader(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(14)),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  AppShimmerLoader(height: 12, width: 70),
                                  SizedBox(height: 8),
                                  AppShimmerLoader(height: 10, width: 50),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      final items = productSnapshot.data ?? [];
                      final query = _searchCtrl.text.trim().toLowerCase();

                      final filtered = items.where((p) {
                        return _matchesSearch(p, query) &&
                            _matchesCategory(p, _selectedCategory);
                      }).toList();

                      final trendingItems =
                          items.where((p) => p.isTrending).toList();

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFC29B40)
                                            .withOpacity(0.45),
                                        width: 2,
                                      ),
                                      image: headerPhotoUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(headerPhotoUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: const Color(0xFFF1E4BE),
                                    ),
                                    child: headerPhotoUrl.isEmpty
                                        ? Center(
                                            child: Text(
                                              displayName.isNotEmpty
                                                  ? displayName[0].toUpperCase()
                                                  : 'M',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF7A5A12),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFC29B40),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'M',
                                                  style: GoogleFonts.cinzel(
                                                    color: const Color(0xFF7C1820),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Mix',
                                              style: GoogleFonts.playfairDisplay(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 24,
                                                color: const Color(0xFF1D1D1F),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isGuest
                                              ? 'Welcome, Guest 👋'
                                              : 'Hi, $displayName 👋',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black87,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _openNotificationsPanel,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withOpacity(0.06),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.notifications_none_rounded,
                                            color: Color(0xFF1D1D1F),
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_isGuest)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC29B40).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          const Color(0xFFC29B40).withOpacity(0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline_rounded,
                                        color: Color(0xFF7A5A12),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'You are browsing as a guest. Sign in to save favorites, confirm rides, save addresses, and checkout orders.',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF7A5A12),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      TextButton(
                                        onPressed: _goToLogin,
                                        child: Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF7A5A12),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (previewController.isPreviewMode)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFFC29B40).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFC29B40)
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.visibility_rounded,
                                        color: Color(0xFF7A5A12),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Preview Mode',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF7A5A12),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search products, categories, variants...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: StreamBuilder<String>(
                                stream: _firebaseService.watchSelectedAddress(),
                                builder: (context, addressSnapshot) {
                                  final selectedAddress =
                                      addressSnapshot.data ?? '';

                                  return StreamBuilder<String>(
                                    stream:
                                        _firebaseService.watchVendorPickupAddress(),
                                    builder: (context, vendorSnapshot) {
                                      final vendorAddress =
                                          vendorSnapshot.data ??
                                              AppConstants.defaultVendorLocation;

                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFFE8DDC0),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.04),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_rounded,
                                                  color: Color(0xFFC29B40),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Selected delivery location',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          const Color(0xFF1D1D1F),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _isGuest
                                                  ? 'Sign in to save and use delivery addresses'
                                                  : (selectedAddress.isEmpty
                                                      ? 'No saved address selected yet'
                                                      : selectedAddress),
                                              style: GoogleFonts.poppins(
                                                color: (_isGuest ||
                                                        selectedAddress.isEmpty)
                                                    ? Colors.black45
                                                    : Colors.black87,
                                                fontSize: 11,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Vendor Pickup: $vendorAddress',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black54,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MainActionCard(
                                      title: 'Book a Ride',
                                      icon:
                                          Icons.directions_car_filled_rounded,
                                      iconBg: const Color(0xFFE7F0FF),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RiderHomeScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MainActionCard(
                                      title: 'Shop Products',
                                      icon: Icons.shopping_cart_rounded,
                                      iconBg: const Color(0xFFF7F0E0),
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.payments_outlined,
                                      label: 'Pay',
                                      onTap: _isGuest ? _goToLogin : () {},
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.receipt_long_rounded,
                                      label: 'My Orders',
                                      onTap: _isGuest
                                          ? _goToLogin
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => OrderScreen(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.history_rounded,
                                      label: 'History',
                                      onTap: _isGuest
                                          ? _goToLogin
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => OrderScreen(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),
                                  Expanded(
                                    child: _QuickActionItem(
                                      icon: Icons.star_rounded,
                                      label: 'Favorites',
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfileScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 14)),

                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 40,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (_, i) {
                                  final item = categories[i];
                                  final selected = item == _selectedCategory;
                                  return ChoiceChip(
                                    label: Text(item),
                                    selected: selected,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = item,
                                    ),
                                    selectedColor: const Color(0xFFC29B40),
                                    labelStyle: GoogleFonts.poppins(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.black.withOpacity(0.08),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemCount: categories.length,
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 10)),

                          if (activeServices.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  children: activeServices.map((service) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: ActiveServiceCard(
                                        icon: service.type == 'delivery'
                                            ? Icons.delivery_dining_rounded
                                            : Icons.local_taxi_rounded,
                                        title: service.type == 'delivery'
                                            ? 'Delivery ${service.driver ?? 'in progress'}'
                                            : 'Driver: ${service.driver ?? 'Searching...'}',
                                        subtitle:
                                            '${service.pickup} → ${service.destination}',
                                        status: service.status,
                                        eta: service.eta.isEmpty
                                            ? null
                                            : service.eta,
                                        trailingText: service.eta.isEmpty
                                            ? (service.type == 'delivery'
                                                ? 'Delivery in progress 📦'
                                                : 'Driver is coming 🚗')
                                            : 'ETA: ${service.eta}',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RideDetailScreen(
                                                ride: service,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Trending Now 🔥',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: const Color(0xFF1D1D1F),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (trendingItems.isEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: EmptyStateCard(
                                  icon:
                                      Icons.local_fire_department_outlined,
                                  title: 'No trending products yet',
                                  subtitle:
                                      'Mark products as trending from admin to show them here.',
                                ),
                              ),
                            )
                          else
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 210,
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: trendingItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, i) {
                                    final product = trendingItems[i];
                                    return _TrendingProductCard(
                                      product: product,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailScreen(
                                              product: product,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(child: SizedBox(height: 16)),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'All Products',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: const Color(0xFF1D1D1F),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (filtered.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: EmptyStateCard(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'No products found',
                                  subtitle:
                                      'Try another search or category.',
                                ),
                              ),
                            )
                          else
                            StreamBuilder<List<String>>(
                              stream: _firebaseService.watchFavorites(),
                              builder: (context, favSnapshot) {
                                final favorites = favSnapshot.data ?? [];

                                return SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    8,
                                  ),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (_, i) {
                                        final product = filtered[i];
                                        final isFavorite =
                                            favorites.contains(product.id);

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ProductDetailScreen(
                                                  product: product,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFE9DFC6),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.vertical(
                                                          top: Radius.circular(20),
                                                        ),
                                                        child: _hasValidImage(
                                                                product.imageUrl)
                                                            ? Image.network(
                                                                product.imageUrl,
                                                                width: double.infinity,
                                                                fit: BoxFit.cover,
                                                                loadingBuilder:
                                                                    (context,
                                                                        child,
                                                                        progress) {
                                                                  if (progress ==
                                                                      null) {
                                                                    return child;
                                                                  }
                                                                  return Container(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade100,
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                errorBuilder: (_,
                                                                        __,
                                                                        ___) =>
                                                                    Container(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child:
                                                                      const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .image_not_supported,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                                child:
                                                                    const Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                  ),
                                                                ),
                                                              ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        left: 8,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (product.isTrending)
                                                              _MiniTag(
                                                                label:
                                                                    'Trending',
                                                                color: const Color(
                                                                  0xFFFF7A00,
                                                                ),
                                                              ),
                                                            if (product.featured)
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  top: 4,
                                                                ),
                                                                child: _MiniTag(
                                                                  label:
                                                                      'Featured',
                                                                  color:
                                                                      const Color(
                                                                    0xFFC29B40,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            if (_isGuest) {
                                                              await _goToLogin();
                                                              return;
                                                            }
                                                            await _firebaseService
                                                                .toggleFavorite(
                                                              product.id,
                                                            );
                                                          },
                                                          child: CircleAvatar(
                                                            radius: 14,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: Icon(
                                                              isFavorite
                                                                  ? Icons.favorite
                                                                  : Icons
                                                                      .favorite_border,
                                                              color: isFavorite
                                                                  ? Colors
                                                                      .redAccent
                                                                  : Colors.black,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                    8,
                                                    8,
                                                    8,
                                                    8,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                          color: const Color(
                                                            0xFF1D1D1F,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        product.primaryCategory,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '₦${product.price.toStringAsFixed(0)}',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color:
                                                                    const Color(
                                                                  0xFF1D1D1F,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                0xFFC29B40,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                999,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Buy',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                color:
                                                                    Colors.white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: filtered.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.62,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                  ),
                                );
                              },
                            ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF3D47A),
                                      Color(0xFFC29B40),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _isGuest
                                            ? 'Sign in to unlock favorites, delivery checkout, ride booking, and personal tracking.'
                                            : 'Live route pricing now powers rides and deliveries across Nigeria!',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF3D2A00),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (!widget.showBottomNav) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F5EF),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFFC29B40),
        unselectedItemColor: Colors.black45,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          } else if (index == 2) {
            if (_isGuest) {
              _goToLogin();
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TrendingProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _TrendingProductCard({
    required this.product,
    required this.onTap,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE9DFC6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: _hasValidImage
                    ? Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.primaryCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₦${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC29B40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MainActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DDC0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1D1D1F),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8DDC0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF1D1D1F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
