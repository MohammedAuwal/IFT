import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final categories = const [
    'All',
    'Spices',
    'Flours',
    'Foods',
    'Oils',
    'General',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? 'User');

    final body = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC29B40).withOpacity(0.45),
                      width: 2,
                    ),
                    image: user?.photoURL != null && user!.photoURL!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(user.photoURL!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: const Color(0xFFF1E4BE),
                  ),
                  child: (user?.photoURL == null || user!.photoURL!.isEmpty)
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
                          const Icon(
                            Icons.auto_awesome_mosaic_rounded,
                            color: Color(0xFFC29B40),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mix',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hi, $displayName 👋',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
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
                            color: Colors.black.withOpacity(0.06),
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
              ],
            ),
          ),
          if (previewController.isPreviewMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC29B40).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC29B40).withOpacity(0.25),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8DDC0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFC29B40),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your current location',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1D1D1F),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Click to set destination/pickup',
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _MainActionCard(
                    title: 'Book a Ride',
                    icon: Icons.directions_car_filled_rounded,
                    iconBg: const Color(0xFFE7F0FF),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionItem(
                    icon: Icons.payments_outlined,
                    label: 'Pay',
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _QuickActionItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'My Orders',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderScreen()),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _QuickActionItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderScreen()),
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
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 10),
          StreamBuilder<List<RideModel>>(
            stream: _firebaseService.watchUserRides(),
            builder: (context, snapshot) {
              final rides = snapshot.data ?? [];
              RideModel? activeRide;

              try {
                activeRide = rides.firstWhere(
                  (r) => r.status != 'completed' && r.status != 'cancelled',
                );
              } catch (_) {
                activeRide = null;
              }

              return Expanded(
                child: StreamBuilder<List<ProductModel>>(
                  stream: _repo.watchProducts(),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState == ConnectionState.waiting) {
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

                    final filtered = items.where((p) {
                      final q = _searchCtrl.text.trim().toLowerCase();
                      final matchesSearch = q.isEmpty ||
                          p.name.toLowerCase().contains(q) ||
                          p.description.toLowerCase().contains(q);

                      final matchesCategory = _selectedCategory == 'All' ||
                          p.category.toLowerCase() ==
                              _selectedCategory.toLowerCase();

                      return matchesSearch && matchesCategory;
                    }).toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search products',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, i) {
                              final item = categories[i];
                              final selected = item == _selectedCategory;
                              return ChoiceChip(
                                label: Text(item),
                                selected: selected,
                                onSelected: (_) => setState(() => _selectedCategory = item),
                                selectedColor: const Color(0xFFC29B40),
                                labelStyle: GoogleFonts.poppins(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.black.withOpacity(0.08),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemCount: categories.length,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (activeRide != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: ActiveServiceCard(
                              icon: Icons.local_taxi_rounded,
                              title: 'Driver: ${activeRide.driver ?? 'Searching...'}',
                              subtitle:
                                  '${activeRide.pickup} → ${activeRide.destination}',
                              status: activeRide.status,
                              eta: activeRide.eta.isEmpty ? null : activeRide.eta,
                              trailingText: activeRide.eta.isEmpty
                                  ? 'Driver is coming 🚗'
                                  : 'ETA: ${activeRide.eta}',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RideDetailScreen(ride: activeRide!),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (filtered.isEmpty)
                          const Expanded(
                            child: EmptyStateCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'No products found',
                              subtitle: 'Try another search or category.',
                            ),
                          )
                        else
                          Expanded(
                            child: StreamBuilder<List<String>>(
                              stream: _firebaseService.watchFavorites(),
                              builder: (context, favSnapshot) {
                                final favorites = favSnapshot.data ?? [];

                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  itemCount: filtered.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.62,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemBuilder: (_, i) {
                                    final product = filtered[i];
                                    final isFavorite =
                                        favorites.contains(product.id);

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(
                                              product: product,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFFE9DFC6),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
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
                                                    child: Image.network(
                                                      product.imageUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              Container(
                                                        color: Colors.grey.shade200,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons
                                                                .image_not_supported,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        await _firebaseService
                                                            .toggleFavorite(
                                                          product.id,
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        radius: 14,
                                                        backgroundColor: Colors.white,
                                                        child: Icon(
                                                          isFavorite
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color: isFavorite
                                                              ? Colors.redAccent
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
                                              padding: const EdgeInsets.fromLTRB(
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
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                      color: const Color(
                                                        0xFF1D1D1F,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '₦${product.price.toStringAsFixed(0)}',
                                                          style: GoogleFonts.poppins(
                                                            color:
                                                                const Color(0xFF1D1D1F),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFC29B40,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                            999,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Buy',
                                                          style:
                                                              GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w700,
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
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                                const Text('🔥', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '20% off rides this week!',
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
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
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
              MaterialPageRoute(builder: (_) => CartScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
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
