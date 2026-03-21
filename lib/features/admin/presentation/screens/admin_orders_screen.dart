import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class AdminOrdersScreen extends StatelessWidget {
  AdminOrdersScreen({super.key});

  final firebaseService = FirebaseService();

  RideModel? _findDeliveryRide(List<RideModel> rides, OrderModel order) {
    try {
      return rides.firstWhere(
        (ride) => ride.id == order.deliveryRideId || ride.orderId == order.id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final isSuperAdmin =
        FirebaseAuth.instance.currentUser?.uid == AppConstants.superAdminUid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        title: Text(
          'Manage Orders',
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
      body: FutureBuilder<bool>(
        future: firebaseService.isAdmin(),
        builder: (context, adminSnapshot) {
          if (adminSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final isAdmin = adminSnapshot.data ?? false;

          final ordersStream = isSuperAdmin
              ? firebaseService.watchAllOrders()
              : (isAdmin
                  ? firebaseService.watchAssignedOrdersForAdmin()
                  : firebaseService.watchAllOrders());

          final ridesStream = isSuperAdmin
              ? firebaseService.watchAllRides()
              : firebaseService.watchAssignedRidesForAdmin();

          return StreamBuilder<List<OrderModel>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Text(
                    isSuperAdmin
                        ? 'No orders yet'
                        : 'No assigned orders yet',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                );
              }

              return StreamBuilder<List<RideModel>>(
                stream: ridesStream,
                builder: (context, rideSnapshot) {
                  final rides = rideSnapshot.data ?? [];

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final order = orders[i];
                      final deliveryRide = _findDeliveryRide(rides, order);

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
                                  order.id,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (order.escalatedToSuperAdmin)
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
                            const SizedBox(height: 6),
                            Text(
                              'Total: ₦${order.totalAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFC29B40),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Order Status: ${order.status}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                              ),
                            ),
                            if (order.assignedAdminName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Assigned Admin: ${order.assignedAdminName}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (order.assignmentMethod.isNotEmpty)
                              Text(
                                'Assignment: ${order.assignmentMethod}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              'Admin Load Snapshot: ${order.activeAdminLoad}',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            if (order.deliveryAddress.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Delivery Address: ${order.deliveryAddress}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (deliveryRide != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Delivery Status: ${deliveryRide.status}',
                                style: GoogleFonts.poppins(
                                  color: Colors.lightBlueAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'ETA: ${deliveryRide.eta} • ${deliveryRide.distanceKm.toStringAsFixed(1)} km',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _statusButton(context, order.id, 'pending'),
                                _statusButton(context, order.id, 'processing'),
                                _statusButton(context, order.id, 'delivered'),
                                if (isSuperAdmin)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminReassignmentScreen(order: order),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    label: const Text('Reassign'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusButton(BuildContext context, String orderId, String status) {
    return ElevatedButton(
      onPressed: () async {
        await firebaseService.updateOrderStatus(
          orderId: orderId,
          status: status,
        );
      },
      child: Text(status),
    );
  }
}
