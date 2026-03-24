import 'package:flutter/material.dart';
import 'package:mix/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mix/features/admin/presentation/screens/admin_escalation_dashboard_screen.dart';
import 'package:mix/features/admin/presentation/screens/admin_orders_screen.dart';
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
    if (navigator == null || _isNavigating) return;

    _isNavigating = true;

    try {
      final type = (data['type'] ?? '').toString().toLowerCase();
      final targetScreen =
          (data['targetScreen'] ?? '').toString().toLowerCase();
      final targetId = (data['targetId'] ?? '').toString();

      if (targetScreen == 'admin_escalation_dashboard' ||
          type.contains('escalation')) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AdminEscalationDashboardScreen(),
            settings: RouteSettings(
              name: 'admin_escalation_dashboard',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (targetScreen == 'admin_orders' || type.contains('admin_assignment_order')) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => AdminOrdersScreen(),
            settings: RouteSettings(
              name: 'admin_orders',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (type.contains('ride') ||
          type.contains('delivery') ||
          targetScreen == 'ride_detail' ||
          targetScreen == 'admin_rides') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const RiderHomeScreen(),
            settings: RouteSettings(
              name: 'rider_home',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (type.contains('order') ||
          targetScreen == 'order_detail' ||
          targetScreen == 'orders') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => OrderScreen(),
            settings: RouteSettings(
              name: 'orders',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      if (type.contains('admin_assignment') || targetScreen == 'admin_dashboard') {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
            settings: RouteSettings(
              name: 'admin_dashboard',
              arguments: targetId,
            ),
          ),
        );
        return;
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => const MainShellScreen(),
          settings: RouteSettings(
            name: 'main_shell',
            arguments: targetId,
          ),
        ),
      );
    } catch (_) {
    } finally {
      _isNavigating = false;
    }
  }
}
