import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/features/admin/presentation/screens/add_product_screen.dart';
import 'package:mix/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:mix/features/admin/presentation/screens/admin_rides_screen.dart';
import 'package:mix/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:mix/features/admin/presentation/screens/manage_categories_screen.dart';
import 'package:mix/features/admin/presentation/screens/manage_products_screen.dart';
import 'package:mix/features/products/presentation/screens/product_detail_screen.dart';
import 'package:mix/models/product_model.dart';
import 'package:mix/services/admin_preview_scope.dart';
import 'package:mix/services/firebase_auth_service.dart';
import 'package:mix/services/firebase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = FirebaseAuthService();
  final _firebaseService = FirebaseService();

  final _adminUidCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _vendorPickupCtrl = TextEditingController();

  bool _addingAdmin = false;
  bool _loggingOut = false;
  bool _savingVendorAddress = false;

  bool get _isSuperAdmin =>
      FirebaseAuth.instance.currentUser?.uid == AppConstants.superAdminUid;

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _addAdmin() async {
    final uid = _adminUidCtrl.text.trim();
    final email = _adminEmailCtrl.text.trim();

    if (uid.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin UID and email are required'),
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text('Admin added successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add admin: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _addingAdmin = false);
    }
  }

  Future<void> _saveVendorPickupAddress() async {
    final address = _vendorPickupCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter vendor/shop pickup address'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _savingVendorAddress = true);

    try {
      await _firebaseService.updateVendorPickupAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor pickup address updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update pickup address: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingVendorAddress = false);
    }
  }

  Future<void> _switchToUserView() async {
    AdminPreviewScope.of(context).enterPreviewMode();
    if (!mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Log out?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'You are about to sign out of the admin account.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC29B40),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Log out',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      AdminPreviewScope.of(context).reset();
      await _authService.signOut();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.login);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
    _firebaseService.seedDefaultAppSettings();
  }

  @override
  void dispose() {
    _adminUidCtrl.dispose();
    _adminEmailCtrl.dispose();
    _vendorPickupCtrl.dispose();
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
              'Manage products, categories, rides & orders',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: _switchToUserView,
              icon: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFFC29B40),
                size: 18,
              ),
              label: Text(
                'User View',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFC29B40),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout_rounded, color: Colors.white),
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
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are in admin mode. Switch to User View to preview the customer experience and your uploaded products.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: _firebaseService.watchProductsCount(),
            builder: (context, pSnap) {
              return StreamBuilder<int>(
                stream: _firebaseService.watchOrdersCount(),
                builder: (context, oSnap) {
                  final products = pSnap.data ?? 0;
                  final orders = oSnap.data ?? 0;

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Products',
                          value: '$products',
                          color: gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Orders',
                          value: '$orders',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<int>(
            stream: _firebaseService.watchRidesCount(),
            builder: (context, rSnap) {
              return StreamBuilder<int>(
                stream: _firebaseService.watchAdminsCount(),
                builder: (context, aSnap) {
                  final rides = rSnap.data ?? 0;
                  final admins = aSnap.data ?? 1;

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Rides',
                          value: '$rides',
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Admins',
                          value: '$admins',
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 18),
          _sectionCard(
            card,
            child: StreamBuilder<String>(
              stream: _firebaseService.watchVendorPickupAddress(),
              builder: (context, snapshot) {
                final currentAddress = snapshot.data ?? AppConstants.defaultVendorLocation;

                if (_vendorPickupCtrl.text.trim().isEmpty) {
                  _vendorPickupCtrl.text = currentAddress;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendor / Shop Pickup Address',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All delivery rides will start from this address.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _vendorPickupCtrl,
                      hint: 'Enter real shop/vendor pickup address in Nigeria',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savingVendorAddress ? null : _saveVendorPickupAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                        ),
                        child: _savingVendorAddress
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Save Pickup Address',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: $currentAddress',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_box_outlined,
                  title: 'Add Product',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddProductScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Manage Products',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageProductsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Orders',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminOrdersScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.local_taxi_rounded,
                  title: 'Rides / Delivery',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminRidesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoriesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.visibility_outlined,
                  title: 'User Preview',
                  onTap: _switchToUserView,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
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
                              (admin['email'] ?? '').toString(),
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Admin account',
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
            'My Uploaded Products',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ProductModel>>(
            stream: _firebaseService.watchMyUploadedProducts(),
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
                    'You have not uploaded any product yet',
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
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _hasValidImage(product.imageUrl)
                              ? Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.white10,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white54,
                                  ),
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
                        '₦${product.price.toStringAsFixed(2)} • ${product.normalizedCategories.join(', ')} • Stock ${product.stockQuantity}',
                        style: GoogleFonts.poppins(color: gold, fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: const Color(0xFF11141A),
                        iconColor: Colors.white70,
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
                                builder: (_) =>
                                    EditProductScreen(product: product),
                              ),
                            );
                          } else if (value == 'delete') {
                            await _firebaseService.deleteProduct(product.id);
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
                              style:
                                  GoogleFonts.poppins(color: Colors.redAccent),
                            ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFC29B40)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white54,
        ),
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
