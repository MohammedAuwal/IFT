import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/features/products/data/product_repository.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/cloudinary_service.dart';
import 'package:mix/services/firebase_auth_service.dart';
import 'package:mix/services/image_pick_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = FirebaseAuthService();
  final _repo = ProductRepository();
  final _cloudinaryService = CloudinaryService();
  final _imageService = ImagePickService();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final file = await _imageService.pickImageWithFallback();

    if (file == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    setState(() => _selectedImage = file);
  }

  Future<void> _uploadProduct() async {
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || description.isEmpty || price == null || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields and select an image')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);

      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final product = ProductModel(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      await _repo.addProduct(product);

      _nameCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();

      setState(() => _selectedImage = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Manage products & services',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () async => _authService.signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Product',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                _Field(controller: _nameCtrl, hint: 'Product name'),
                const SizedBox(height: 12),
                _Field(controller: _descCtrl, hint: 'Description', maxLines: 3),
                const SizedBox(height: 12),
                _Field(
                  controller: _priceCtrl,
                  hint: 'Price',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11141A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded, color: Colors.white70, size: 34),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to pick image',
                                style: GoogleFonts.poppins(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Image picker + file picker fallback',
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _uploadProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Upload Product',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Live Products',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ProductModel>>(
            stream: _repo.watchProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'No products yet',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                );
              }

              return Column(
                children: items.map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.white10,
                            child: const Icon(Icons.image_not_supported, color: Colors.white54),
                          ),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '₦${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(color: gold),
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          await _repo.deleteProduct(product.id);
                        },
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF11141A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
