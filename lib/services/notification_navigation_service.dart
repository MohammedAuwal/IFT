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

  Future<void> handlePayload(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = (data['type'] ?? '').toString();

    if (type.contains('ride') || type.contains('delivery')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
      );
      return;
    }

    if (type.contains('order')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderScreen()),
      );
      return;
    }

    if (type.contains('escalation') || type.contains('admin_assignment')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminEscalationDashboardScreen(),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }
}
