import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/firebase_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  Future<void> _promptLogin(BuildContext context, String actionText) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Sign in required',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Please sign in or create an account to $actionText.',
              style: GoogleFonts.poppins(fontSize: 13.5, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Later',
                  style: GoogleFonts.poppins(),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC29B40),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!go) return;
    if (!context.mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final variantText =
        product.variants.isEmpty ? 'No variants' : product.variants.join(', ');
    final categoryText = product.normalizedCategories.join(', ');
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          product.name,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (!isGuest)
            StreamBuilder<List<String>>(
              stream: firebaseService.watchFavorites(),
              builder: (context, snapshot) {
                final favorites = snapshot.data ?? [];
                final isFavorite = favorites.contains(product.id);

                return IconButton(
                  onPressed: () async {
                    await firebaseService.toggleFavorite(product.id);
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.black,
                  ),
                );
              },
            )
          else
            IconButton(
              onPressed: () => _promptLogin(context, 'save favorites'),
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.black,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: _hasValidImage
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 42),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 42),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (product.isTrending)
                _StatusChip(
                  label: 'Trending',
                  bgColor: const Color(0xFFFFE3D2),
                  textColor: const Color(0xFFAA4A00),
                  icon: Icons.local_fire_department_rounded,
                ),
              if (product.featured)
                _StatusChip(
                  label: 'Featured',
                  bgColor: const Color(0xFFF8E9B0),
                  textColor: const Color(0xFF7A5A12),
                  icon: Icons.star_rounded,
                ),
              _StatusChip(
                label: product.inStock ? 'In Stock' : 'Out of Stock',
                bgColor: product.inStock
                    ? const Color(0xFFDDF5E4)
                    : const Color(0xFFFFE0E0),
                textColor: product.inStock
                    ? const Color(0xFF1F7A39)
                    : const Color(0xFFB42318),
                icon: product.inStock
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₦${product.price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC29B40),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Categories',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(categoryText, style: GoogleFonts.poppins()),
          const SizedBox(height: 18),
          Text(
            'Variants',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(variantText, style: GoogleFonts.poppins()),
          const SizedBox(height: 18),
          Text(
            'Description',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: GoogleFonts.poppins(
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          if (isGuest)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFC29B40).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFC29B40).withOpacity(0.2),
                ),
              ),
              child: Text(
                'You are browsing as a guest. Sign in to save favorites and track your activity across devices.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF7A5A12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: product.inStock
                  ? () async {
                      await firebaseService.addToCart(
                        productId: product.id,
                        name: product.name,
                        price: product.price,
                        imageUrl: product.imageUrl,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isGuest
                                  ? 'Added to guest cart'
                                  : 'Added to cart',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2121),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Add to Cart',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
