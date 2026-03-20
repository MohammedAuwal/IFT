import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class OrderScreen extends StatelessWidget {
  final bool showScaffold;

  OrderScreen({super.key, this.showScaffold = true});

  final firebaseService = FirebaseService();

  RideModel? _findDeliveryRideForOrder(List<RideModel> rides, OrderModel order) {
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
    final content = StreamBuilder<List<OrderModel>>(
      stream: firebaseService.watchOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'No orders yet',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        return StreamBuilder<List<RideModel>>(
          stream: firebaseService.watchUserRides(),
          builder: (context, rideSnapshot) {
            final rides = rideSnapshot.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final order = orders[i];
                final isDelivered = order.status == 'delivered';
                final deliveryRide = _findDeliveryRideForOrder(rides, order);

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDelivered
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          child: Icon(
                            deliveryRide != null
                                ? Icons.delivery_dining_rounded
                                : Icons.receipt_long_rounded,
                            color: isDelivered ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.status,
                                style: GoogleFonts.poppins(
                                  color:
                                      isDelivered ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                              if (order.deliveryAddress.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  order.deliveryAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                              if (deliveryRide != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Delivery: ${deliveryRide.status} • ${deliveryRide.distanceKm.toStringAsFixed(1)} km • ${deliveryRide.eta}',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF8E2121),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '₦${order.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC29B40),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (!showScaffold) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F5EF),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: content,
    );
  }
}
