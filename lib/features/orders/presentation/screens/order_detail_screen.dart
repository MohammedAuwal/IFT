import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<RideModel>>(
        stream: firebaseService.watchUserRides(),
        builder: (context, snapshot) {
          final rides = snapshot.data ?? [];

          RideModel? deliveryRide;
          try {
            deliveryRide = rides.firstWhere(
              (ride) =>
                  ride.id == order.deliveryRideId || ride.orderId == order.id,
            );
          } catch (_) {
            deliveryRide = null;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                order.id,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${order.status}',
                style: GoogleFonts.poppins(
                  color: order.status == 'delivered'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              if (order.deliveryAddress.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Delivery Address: ${order.deliveryAddress}',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                  ),
                ),
              ],
              if (deliveryRide != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Tracking',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${deliveryRide.status}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8E2121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ETA: ${deliveryRide.eta}',
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        'Distance: ${deliveryRide.distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(),
                      ),
                      Text(
                        'Fare: ₦${deliveryRide.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(),
                      ),
                      if (deliveryRide.driver != null)
                        Text(
                          'Driver: ${deliveryRide.driver}',
                          style: GoogleFonts.poppins(),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...order.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (item['name'] ?? '').toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'x${item['qty']}',
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₦${(((item['price'] ?? 0) as num).toDouble() * ((item['qty'] ?? 1) as int)).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC29B40),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Total: ₦${order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
