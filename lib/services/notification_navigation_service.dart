import 'package:flutter/material.dart';
import 'package:mix/features/admin/presentation/screens/admin_escalation_dashboard_screen.dart';
import 'package:mix/features/orders/presentation/screens/order_screen.dart';
import 'package:mix/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:mix/features/shell/presentation/screens/main_shell_screen.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _isNavigating = false;

  Future<void> handlePayload(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;

    if (navigator == null || context == null) return;
    if (_isNavigating) return;

    _isNavigating = true;

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final safeNavigator = navigatorKey.currentState;
        final safeContext = navigatorKey.currentContext;

        if (safeNavigator == null || safeContext == null) {
          _isNavigating = false;
          return;
        }

        final type = (data['type'] ?? '').toString();

        if (type.contains('ride') || type.contains('delivery')) {
          await safeNavigator.push(
            MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
          );
        } else if (type.contains('order')) {
          await safeNavigator.push(
            MaterialPageRoute(builder: (_) => OrderScreen()),
          );
        } else if (type.contains('escalation') ||
            type.contains('admin_assignment')) {
          await safeNavigator.push(
            MaterialPageRoute(
              builder: (_) => AdminEscalationDashboardScreen(),
            ),
          );
        } else {
          await safeNavigator.push(
            MaterialPageRoute(builder: (_) => const MainShellScreen()),
          );
        }

        _isNavigating = false;
      });
    } catch (_) {
      _isNavigating = false;
    }
  }
}
