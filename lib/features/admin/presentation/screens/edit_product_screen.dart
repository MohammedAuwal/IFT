import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/cloudinary_service.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:mix/services/image_pick_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _firebaseService = FirebaseService();
  final _cloudinaryService = CloudinaryService();
  final _imageService = ImagePickService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _variantsCtrl;
  late final TextEditingController _stockQtyCtrl;
  late final TextEditingController _promoTextCtrl;
  late final TextEditingController _promoDiscountCtrl;

  File? _selectedImage;
  late bool _featured;
  late bool _inStock;
  String? _selectedCategory;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description);
    _priceCtrl = TextEditingController(text: widget.product.price.toString());
    _variantsCtrl = TextEditingController(text: widget.product.variants.join(', '));
    _stockQtyCtrl = TextEditingController(text: widget.product.stockQuantity.toString());
    _promoTextCtrl = TextEditingController(text: widget.product.promoText);
    _promoDiscountCtrl =
        TextEditingController(text: widget.product.promoDiscountPercent.toString());
    _featured = widget.product.featured;
    _inStock = widget.product.inStock;
    _selectedCategory = widget.product.category;
  }

  Future<void> _pickImage() async {
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;

    final sizeBytes = await file.length();
    const maxBytes = 3 * 1024 * 1024;

    if (sizeBytes > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image too large. Max allowed is 3MB')),
      );
      return;
    }

    setState(() => _selectedImage = file);
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceCtrl.text.trim());
    final stockQty = int.tryParse(_stockQtyCtrl.text.trim()) ?? 0;
    final promoDiscount = double.tryParse(_promoDiscountCtrl.text.trim()) ?? 0;

    if (price == null) return;

    setState(() => _loading = true);

    try {
      String imageUrl = widget.product.imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      }

      final updated = ProductModel(
        id: widget.product.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: price,
        imageUrl: imageUrl,
        createdBy: widget.product.createdBy,
        createdAt: widget.product.createdAt,
        category: (_selectedCategory == null || _selectedCategory!.trim().isEmpty)
            ? 'General'
            : _selectedCategory!.trim(),
        featured: _featured,
        inStock: _inStock,
        stockQuantity: stockQty,
        variants: _variantsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        promoText: _promoTextCtrl.text.trim(),
        promoDiscountPercent: promoDiscount,
      );

      await _firebaseService.updateProduct(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: $e')),
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
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Edit Product',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                _Field(controller: _nameCtrl, hint: 'Product name'),
                const SizedBox(height: 12),
                _Field(controller: _descCtrl, hint: 'Description', maxLines: 4),
                const SizedBox(height: 12),
                _Field(controller: _priceCtrl, hint: 'Price', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                StreamBuilder<List<String>>(
                  stream: _firebaseService.watchCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? ['General'];
                    _selectedCategory ??= categories.isNotEmpty ? categories.first : 'General';

                    return DropdownButtonFormField<String>(
                      value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                      dropdownColor: const Color(0xFF11141A),
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF11141A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                _Field(controller: _stockQtyCtrl, hint: 'Stock quantity', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _Field(controller: _variantsCtrl, hint: 'Variants comma separated'),
                const SizedBox(height: 12),
                _Field(controller: _promoTextCtrl, hint: 'Promo text'),
                const SizedBox(height: 12),
                _Field(controller: _promoDiscountCtrl, hint: 'Promo discount %', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                  title: Text('Featured', style: GoogleFonts.poppins(color: Colors.white)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _inStock,
                  onChanged: (v) => setState(() => _inStock = v),
                  title: Text('In stock', style: GoogleFonts.poppins(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11141A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Image.network(widget.product.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Changes',
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
