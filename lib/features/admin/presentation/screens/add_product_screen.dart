import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/products/data/product_repository.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/cloudinary_service.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:mix/services/image_pick_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _repo = ProductRepository();
  final _cloudinaryService = CloudinaryService();
  final _imageService = ImagePickService();
  final _firebaseService = FirebaseService();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _variantsCtrl = TextEditingController();
  final _stockQtyCtrl = TextEditingController(text: '0');
  final _promoTextCtrl = TextEditingController();
  final _promoDiscountCtrl = TextEditingController(text: '0');

  File? _selectedImage;
  bool _featured = false;
  bool _isTrending = false;
  bool _inStock = true;
  bool _loading = false;

  List<String> _selectedCategories = ['General'];

  Future<void> _pickImage() async {
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;

    final sizeBytes = await file.length();
    const maxBytes = 3 * 1024 * 1024;

    if (sizeBytes > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image too large. Max allowed is 3MB'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _selectedImage = file);
  }

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedCategories.contains(category)) {
          _selectedCategories.add(category);
        }
      } else {
        _selectedCategories.remove(category);
      }

      if (_selectedCategories.isEmpty) {
        _selectedCategories = ['General'];
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final stockQty = int.tryParse(_stockQtyCtrl.text.trim()) ?? 0;
    final promoDiscount = double.tryParse(_promoDiscountCtrl.text.trim()) ?? 0;
    final variants = _variantsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (name.isEmpty || description.isEmpty || price == null || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select an image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final categories = _selectedCategories.toSet().toList();

    if (_featured && !categories.contains('Featured')) {
      categories.add('Featured');
    }
    if (_isTrending && !categories.contains('Trending')) {
      categories.add('Trending');
    }

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
        category: categories.isEmpty ? 'General' : categories.first,
        categories: categories,
        featured: _featured,
        isTrending: _isTrending,
        inStock: _inStock,
        stockQuantity: stockQty,
        variants: variants,
        promoText: _promoTextCtrl.text.trim(),
        promoDiscountPercent: promoDiscount,
      );

      await _repo.addProduct(product);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
          behavior: SnackBarBehavior.floating,
        ),
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
    _variantsCtrl.dispose();
    _stockQtyCtrl.dispose();
    _promoTextCtrl.dispose();
    _promoDiscountCtrl.dispose();
    super.dispose();
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
                'Add Product',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a new product',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _Field(controller: _nameCtrl, hint: 'Product name'),
                const SizedBox(height: 12),
                _Field(controller: _descCtrl, hint: 'Description', maxLines: 4),
                const SizedBox(height: 12),
                _Field(
                  controller: _priceCtrl,
                  hint: 'Price',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                Text(
                  'Categories',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<String>>(
                  stream: _firebaseService.watchCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? const ['General'];

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        final selected =
                            _selectedCategories.contains(category);

                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (value) => _toggleCategory(category, value),
                          selectedColor: gold,
                          backgroundColor: const Color(0xFF11141A),
                          labelStyle: GoogleFonts.poppins(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: selected ? gold : Colors.white12,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _stockQtyCtrl,
                  hint: 'Stock quantity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _variantsCtrl,
                  hint: 'Variants (comma separated)',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _promoTextCtrl,
                  hint: 'Promo text e.g 20% off this week',
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _promoDiscountCtrl,
                  hint: 'Promo discount %',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: gold,
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                  title: Text(
                    'Featured product',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: gold,
                  value: _isTrending,
                  onChanged: (v) => setState(() => _isTrending = v),
                  title: Text(
                    'Trending product',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: gold,
                  value: _inStock,
                  onChanged: (v) => setState(() => _inStock = v),
                  title: Text(
                    'In stock',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11141A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.white70,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select product image',
                                style: GoogleFonts.poppins(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Max image size: 3MB',
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Product',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
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
