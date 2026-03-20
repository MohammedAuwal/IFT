import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;

  const RideDetailScreen({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final isDelivery = ride.type == 'delivery';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isDelivery ? 'Delivery Details' : 'Ride Details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isDelivery ? 'Delivery' : 'Ride'} #${ride.id}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                _info('Type', ride.type),
                _info('Pickup', ride.pickup),
                _info('Destination', ride.destination),
                _info('Ride Type', ride.rideType),
                _info('Status', ride.status),
                _info('Driver', ride.driver ?? 'Not assigned yet'),
                _info('ETA', ride.eta.isEmpty ? 'Pending' : ride.eta),
                _info('Distance', '${ride.distanceKm.toStringAsFixed(1)} km'),
                _info('Duration', '${ride.durationMin.ceil()} mins'),
                _info('Fare', '₦${ride.price.toStringAsFixed(0)}'),
                if (ride.orderId != null && ride.orderId!.isNotEmpty)
                  _info('Order', ride.orderId!),
                if (ride.productId != null && ride.productId!.isNotEmpty)
                  _info('Product', ride.productId!),
                if (ride.note.isNotEmpty) _info('Note', ride.note),
                const SizedBox(height: 18),
                if (ride.status != 'completed' && ride.status != 'cancelled')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await firebaseService.cancelRide(ride.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isDelivery
                                    ? 'Delivery cancelled'
                                    : 'Ride cancelled',
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(isDelivery ? 'Cancel Delivery' : 'Cancel Ride'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
