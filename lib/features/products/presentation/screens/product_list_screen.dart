import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/features/cart/presentation/screens/cart_screen.dart';
import 'package:mix/features/orders/presentation/screens/order_screen.dart';
import 'package:mix/features/products/data/product_repository.dart';
import 'package:mix/features/products/presentation/screens/product_detail_screen.dart';
import 'package:mix/features/profile/presentation/screens/profile_screen.dart';
import 'package:mix/models/product_model.dart';

class ProductListScreen extends StatefulWidget {
  ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repo = ProductRepository();
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email ?? 'User');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFC29B40),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mix',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: const Color(0xFF1D1D1F),
                            )),
                        Text(
                          'Hi, $displayName 👋',
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CartScreen()),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ],
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFFC29B40)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your current location',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1D1D1F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
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
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: categories.length,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _repo.watchProducts(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];

                  final filtered = items.where((p) {
                    final q = _searchCtrl.text.trim().toLowerCase();
                    final matchesSearch = q.isEmpty ||
                        p.name.toLowerCase().contains(q) ||
                        p.description.toLowerCase().contains(q);

                    final matchesCategory = _selectedCategory == 'All' ||
                        p.category.toLowerCase() == _selectedCategory.toLowerCase();

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No products found',
                        style: GoogleFonts.poppins(color: Colors.black54),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, i) {
                      final product = filtered[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        product.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (product.featured)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC29B40),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Featured',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
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
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1D1D1F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₦${product.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFC29B40),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      product.inStock ? 'In Stock' : 'Out of Stock',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: product.inStock ? Colors.green : Colors.redAccent,
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
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFFC29B40),
        unselectedItemColor: Colors.black45,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartScreen()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen()));
          } else if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen()));
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
