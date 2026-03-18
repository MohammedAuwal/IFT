import 'package:flutter/material.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/features/admin/presentation/screens/add_product_screen.dart';
import 'package:mix/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mix/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:mix/features/auth/presentation/screens/login_screen.dart';
import 'package:mix/features/cart/presentation/screens/cart_screen.dart';
import 'package:mix/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:mix/features/orders/presentation/screens/order_screen.dart';
import 'package:mix/features/products/presentation/screens/product_list_screen.dart';
import 'package:mix/features/profile/presentation/screens/profile_screen.dart';
import 'package:mix/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:mix/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _route(const _NoExitScreen(child: SplashScreen()));
      case RouteNames.login:
        return _route(const _NoExitScreen(child: LoginScreen()));
      case RouteNames.home:
        return _route(_NoExitScreen(child: ProductListScreen()));
      case RouteNames.admin:
        return _route(_NoExitScreen(child: AdminDashboardScreen()));
      case RouteNames.cart:
        return _route(_NoExitScreen(child: CartScreen()));
      case RouteNames.orders:
        return _route(_NoExitScreen(child: OrderScreen()));
      case RouteNames.profile:
        return _route(_NoExitScreen(child: ProfileScreen()));
      case RouteNames.favorites:
        return _route(_NoExitScreen(child: FavoritesScreen()));
      case RouteNames.addProduct:
        return _route(const AddProductScreen());
      case RouteNames.adminOrders:
        return _route(AdminOrdersScreen());
      case RouteNames.mainShell:
        return _route(const _NoExitScreen(child: MainShellScreen()));
      default:
        return _route(
          const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static MaterialPageRoute _route(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  static Future<void> clearAndGo(BuildContext context, String route) async {
    if (!context.mounted) return;
    await Navigator.of(context)
        .pushNamedAndRemoveUntil(route, (route) => false);
  }
}

class _NoExitScreen extends StatelessWidget {
  final Widget child;

  const _NoExitScreen({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: child,
    );
  }
}
