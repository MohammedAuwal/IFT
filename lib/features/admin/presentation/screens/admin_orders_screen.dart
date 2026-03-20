import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: firebaseService.watchAllOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No orders yet',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          return StreamBuilder<List<RideModel>>(
            stream: firebaseService.watchAllRides(),
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
                        Text(
                          order.id,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
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
      ),
    );
  }

  Widget _statusButton(BuildContext context, String orderId, String status) {
    return ElevatedButton(
      onPressed: () async {
        await firebaseService.updateOrderStatus(orderId: orderId, status: status);
      },
      child: Text(status),
    );
  }
}
