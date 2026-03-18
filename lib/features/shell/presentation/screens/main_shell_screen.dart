import 'package:flutter/material.dart';
import 'package:mix/features/cart/presentation/screens/cart_screen.dart';
import 'package:mix/features/orders/presentation/screens/order_screen.dart';
import 'package:mix/features/products/presentation/screens/product_list_screen.dart';
import 'package:mix/features/profile/presentation/screens/profile_screen.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _tabKey = 'main_shell_tab_index';

  final _firebaseService = FirebaseService();
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    ProductListScreen(showBottomNav: false),
    CartScreen(showScaffold: false),
    OrderScreen(showScaffold: false),
    ProfileScreen(showScaffold: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadTab();
  }

  Future<void> _loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_tabKey) ?? 0;
    if (!mounted) return;
    setState(() => _currentIndex = savedIndex);
  }

  Future<void> _saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, index);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _firebaseService.watchCartCount(),
      builder: (context, cartSnapshot) {
        final cartCount = cartSnapshot.data ?? 0;

        return StreamBuilder<List<String>>(
          stream: _firebaseService.watchFavorites(),
          builder: (context, favSnapshot) {
            final favCount = favSnapshot.data?.length ?? 0;

            return Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                selectedItemColor: const Color(0xFFC29B40),
                unselectedItemColor: Colors.black45,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                  _saveTab(index);
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _BadgeIcon(
                      icon: Icons.shopping_cart_rounded,
                      count: cartCount,
                    ),
                    label: 'Cart',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_rounded),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: _BadgeIcon(
                      icon: Icons.person_rounded,
                      count: favCount,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
