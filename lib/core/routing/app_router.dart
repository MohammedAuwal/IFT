import 'package:flutter/material.dart';
import 'package:mix/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mix/features/auth/presentation/screens/login_screen.dart';
import 'package:mix/features/products/presentation/screens/product_list_screen.dart';
import 'package:mix/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String admin = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _route(const _NoExitScreen(child: SplashScreen()));
      case login:
        return _route(const _NoExitScreen(child: LoginScreen()));
      case home:
        return _route(_NoExitScreen(child: ProductListScreen()));
      case admin:
        return _route(_NoExitScreen(child: AdminDashboardScreen()));
      default:
        return _route(
          const _NoExitScreen(
            child: Scaffold(
              body: Center(
                child: Text('Page not found'),
              ),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute _route(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  static Future<void> goToLogin(BuildContext context) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(login, (route) => false);
  }

  static Future<void> goToHome(BuildContext context) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
  }

  static Future<void> goToAdmin(BuildContext context) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(admin, (route) => false);
  }

  static Future<void> goToSplash(BuildContext context) async {
    await Navigator.of(context).pushNamedAndRemoveUntil(splash, (route) => false);
  }
}

class _NoExitScreen extends StatelessWidget {
  final Widget child;

  const _NoExitScreen({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: child,
    );
  }
}
