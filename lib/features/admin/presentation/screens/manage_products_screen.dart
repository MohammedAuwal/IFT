import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:mix/features/products/presentation/screens/product_detail_screen.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/firebase_service.dart';

class ManageProductsScreen extends StatelessWidget {
  ManageProductsScreen({super.key});

  final FirebaseService _firebaseService = FirebaseService();

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _deleteProduct(BuildContext context, ProductModel product) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Delete "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await _firebaseService.deleteProduct(product.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M',
                  style: GoogleFonts.cinzel(
                    color: wine,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Manage Products',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                themeController.toggleDarkMode(!themeController.isDarkMode),
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _firebaseService.watchAllProducts(),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products yet',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];

              return Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: _hasValidImage(product.imageUrl)
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₦${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.normalizedCategories.join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF11141A),
                    iconColor: Colors.white,
                    onSelected: (value) async {
                      if (value == 'preview') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        );
                      } else if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProductScreen(product: product),
                          ),
                        );
                      } else if (value == 'delete') {
                        await _deleteProduct(context, product);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'preview',
                        child: Text(
                          'Preview',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(color: Colors.redAccent),
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
    );
  }
}
