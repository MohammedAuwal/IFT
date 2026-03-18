import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/features/admin/presentation/screens/add_product_screen.dart';
import 'package:mix/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:mix/features/products/data/product_repository.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/firebase_auth_service.dart';
import 'package:mix/services/firebase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = FirebaseAuthService();
  final _firebaseService = FirebaseService();
  final _repo = ProductRepository();

  final _adminUidCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();

  bool _addingAdmin = false;

  bool get _isSuperAdmin =>
      FirebaseAuth.instance.currentUser?.uid == AppConstants.superAdminUid;

  Future<void> _addAdmin() async {
    final uid = _adminUidCtrl.text.trim();
    final email = _adminEmailCtrl.text.trim();

    if (uid.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin UID and email are required')),
      );
      return;
    }

    setState(() => _addingAdmin = true);
    try {
      await _firebaseService.addAdmin(uid: uid, email: email);
      _adminUidCtrl.clear();
      _adminEmailCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add admin: $e')),
      );
    } finally {
      if (mounted) setState(() => _addingAdmin = false);
    }
  }

  @override
  void dispose() {
    _adminUidCtrl.dispose();
    _adminEmailCtrl.dispose();
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
              _isSuperAdmin ? 'Super Admin Dashboard' : 'Admin Dashboard',
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            },
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () async => _authService.signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isSuperAdmin) ...[
            _sectionCard(
              card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Admin',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Field(controller: _adminUidCtrl, hint: 'Admin UID'),
                  const SizedBox(height: 12),
                  _Field(controller: _adminEmailCtrl, hint: 'Admin Email'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addingAdmin ? null : _addAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _addingAdmin
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Add Admin',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Current Admins',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firebaseService.watchAdmins(),
                    builder: (context, snapshot) {
                      final admins = snapshot.data ?? [];
                      if (admins.isEmpty) {
                        return Text(
                          'No extra admins yet',
                          style: GoogleFonts.poppins(color: Colors.white54),
                        );
                      }

                      return Column(
                        children: admins.map((admin) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              admin['email'] ?? '',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            subtitle: Text(
                              admin['uid'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
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
                        '₦${product.price.toStringAsFixed(2)} • ${product.category}',
                        style: GoogleFonts.poppins(color: gold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditProductScreen(product: product),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _repo.deleteProduct(product.id);
                            },
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          ),
                        ],
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

  Widget _sectionCard(Color card, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
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
