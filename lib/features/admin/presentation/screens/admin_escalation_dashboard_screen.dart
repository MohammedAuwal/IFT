import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class AdminEscalationDashboardScreen extends StatelessWidget {
  AdminEscalationDashboardScreen({super.key});

  final FirebaseService _firebaseService = FirebaseService();

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      case 'processing':
      case 'ride_in_progress':
      case 'delivery_in_progress':
        return Colors.blueAccent;
      case 'on_the_way':
        return Colors.orange;
      default:
        return const Color(0xFFC29B40);
    }
  }

  Widget _sectionTitle(String text) {
    return Builder(
      builder: (context) => Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final isSuperAdmin =
        _firebaseService.currentUser?.uid == AppConstants.superAdminUid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Escalation Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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
      body: !isSuperAdmin
          ? Center(
              child: Text(
                'Only super admin can view escalations',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            )
          : StreamBuilder<List<RideModel>>(
              stream: _firebaseService.watchEscalatedRides(),
              builder: (context, rideSnapshot) {
                final escalatedRides = rideSnapshot.data ?? [];

                return StreamBuilder<List<OrderModel>>(
                  stream: _firebaseService.watchEscalatedOrders(),
                  builder: (context, orderSnapshot) {
                    final escalatedOrders = orderSnapshot.data ?? [];

                    if (escalatedRides.isEmpty && escalatedOrders.isEmpty) {
                      return Center(
                        child: Text(
                          'No escalated requests right now',
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC29B40).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFC29B40).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFC29B40),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Escalated requests are items that could not be assigned properly and now require super admin action.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (escalatedRides.isNotEmpty) ...[
                          _sectionTitle('Escalated Rides & Deliveries'),
                          const SizedBox(height: 12),
                          ...escalatedRides.map((ride) {
                            final isDelivery = ride.type == 'delivery';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171A21),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        isDelivery
                                            ? 'Escalated Delivery'
                                            : 'Escalated Ride',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Escalated',
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${ride.pickup} → ${ride.destination}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Status: ${ride.status}',
                                    style: GoogleFonts.poppins(
                                      color: _statusColor(ride.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Assignment Method: ${ride.assignmentMethod ?? 'unknown'}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if ((ride.assignedAdminName ?? '').isNotEmpty)
                                    Text(
                                      'Current Owner: ${ride.assignedAdminName}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminReassignmentScreen(
                                                ride: ride,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.swap_horiz_rounded),
                                        label: const Text('Reassign'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _firebaseService.updateRideStatus(
                                            rideId: ride.id,
                                            status: 'searching',
                                          );

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Ride reset to searching'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                        if (escalatedOrders.isNotEmpty) ...[
                          _sectionTitle('Escalated Orders'),
                          const SizedBox(height: 12),
                          ...escalatedOrders.map((order) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171A21),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Escalated Order',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Escalated',
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Order ID: ${order.id}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Address: ${order.deliveryAddress}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Status: ${order.status}',
                                    style: GoogleFonts.poppins(
                                      color: _statusColor(order.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Assignment Method: ${order.assignmentMethod}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (order.assignedAdminName.isNotEmpty)
                                    Text(
                                      'Current Owner: ${order.assignedAdminName}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminReassignmentScreen(
                                                order: order,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.swap_horiz_rounded),
                                        label: const Text('Reassign'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _firebaseService.updateOrderStatus(
                                            orderId: order.id,
                                            status: 'pending',
                                          );

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Order reset to pending'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
