import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/theme/app_theme.dart';
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
    final colors = AppTheme.colorsOf(context);

    final content = StreamBuilder<List<OrderModel>>(
      stream: firebaseService.watchOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'No orders yet',
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
              ),
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
                      color: colors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (isDelivered
                                  ? colors.success
                                  : colors.warning)
                              .withOpacity(0.15),
                          child: Icon(
                            deliveryRide != null
                                ? Icons.delivery_dining_rounded
                                : Icons.receipt_long_rounded,
                            color:
                                isDelivered ? colors.success : colors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.status,
                                style: GoogleFonts.poppins(
                                  color: isDelivered
                                      ? colors.success
                                      : colors.warning,
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
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                              if (deliveryRide != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Delivery: ${deliveryRide.status} • ${deliveryRide.distanceKm.toStringAsFixed(1)} km • ${deliveryRide.eta}',
                                  style: GoogleFonts.poppins(
                                    color: colors.brandSecondary,
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
                            color: colors.brandPrimary,
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
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: content,
    );
  }
}
