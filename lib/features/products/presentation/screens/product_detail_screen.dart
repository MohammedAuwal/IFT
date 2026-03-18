import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final variantText = product.variants.isEmpty
        ? 'No variants'
        : product.variants.join(', ');

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 42),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 10),
          Text(
            product.inStock ? 'Available now' : 'Currently unavailable',
            style: GoogleFonts.poppins(
              color: product.inStock ? Colors.green : Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Category',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(product.category, style: GoogleFonts.poppins()),
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
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
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
