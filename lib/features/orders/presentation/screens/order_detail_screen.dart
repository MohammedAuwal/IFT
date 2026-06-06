import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ift/models/order_model.dart';
import 'package:ift/models/ride_model.dart';
import 'package:ift/services/firebase_service.dart';
import 'package:ift/shared/widgets/app_page_scaffold.dart';
import 'package:ift/shared/widgets/app_section_title.dart';
import 'package:ift/shared/widgets/app_surface_card.dart';
import 'package:ift/core/theme/build_context_theme_x.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Order Details',
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
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${order.status}',
                style: GoogleFonts.poppins(
                  color: order.status == 'delivered'
                      ? colors.success
                      : colors.warning,
                ),
              ),
              if (order.deliveryAddress.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Delivery Address: ${order.deliveryAddress}',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                  ),
                ),
              ],
              if (deliveryRide != null) ...[
                const SizedBox(height: 16),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionTitle(
                        title: 'Delivery Tracking',
                        spacingBottom: 8,
                      ),
                      Text(
                        'Status: ${deliveryRide.status}',
                        style: GoogleFonts.poppins(
                          color: colors.brandSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ETA: ${deliveryRide.eta}',
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Distance: ${deliveryRide.distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Fare: ₦${deliveryRide.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (deliveryRide.driver != null)
                        Text(
                          'Driver: ${deliveryRide.driver}',
                          style: GoogleFonts.poppins(
                            color: colors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...order.items.map((item) {
                return AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (item['name'] ?? '').toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'x${item['qty']}',
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₦${(((item['price'] ?? 0) as num).toDouble() * ((item['qty'] ?? 1) as int)).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: colors.brandPrimary,
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
                  color: colors.textPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
