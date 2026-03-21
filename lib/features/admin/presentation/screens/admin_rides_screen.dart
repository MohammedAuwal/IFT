import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:mix/features/rider/presentation/screens/driver_mode_screen.dart';
import 'package:mix/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class AdminRidesScreen extends StatelessWidget {
  AdminRidesScreen({super.key});

  final firebaseService = FirebaseService();

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      case 'ride_in_progress':
      case 'delivery_in_progress':
        return Colors.blueAccent;
      case 'on_the_way':
        return Colors.orange;
      default:
        return const Color(0xFFC29B40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: firebaseService.isAdmin(),
      builder: (context, adminSnapshot) {
        final isAdmin = adminSnapshot.data ?? false;
        final isSuperAdmin =
            FirebaseAuth.instance.currentUser?.uid == AppConstants.superAdminUid;

        final stream =
            isAdmin ? firebaseService.watchAssignedRidesForAdmin() : firebaseService.watchAllRides();

        return Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F1115),
            elevation: 0,
            title: Text(
              'Manage Rides & Deliveries',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: StreamBuilder<List<RideModel>>(
            stream: stream,
            builder: (context, snapshot) {
              final rides = snapshot.data ?? [];

              if (rides.isEmpty) {
                return Center(
                  child: Text(
                    'No assigned rides yet',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length,
                itemBuilder: (_, i) {
                  final ride = rides[i];
                  final isDelivery = ride.type == 'delivery';

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RideDetailScreen(ride: ride),
                        ),
                      );
                    },
                    child: Container(
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
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${isDelivery ? 'Delivery' : 'Ride'} ID: ${ride.id}',
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
                                  color: isDelivery
                                      ? Colors.blue.withOpacity(0.15)
                                      : const Color(0xFFC29B40).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isDelivery ? 'Delivery' : 'Ride',
                                  style: GoogleFonts.poppins(
                                    color: isDelivery
                                        ? Colors.lightBlueAccent
                                        : const Color(0xFFC29B40),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (ride.escalatedToSuperAdmin)
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
                            'From: ${ride.pickup}',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          Text(
                            'To: ${ride.destination}',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ride Type: ${ride.rideType}',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Distance: ${ride.distanceKm.toStringAsFixed(1)} km • ETA: ${ride.eta}',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fare: ₦${ride.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFC29B40),
                              fontWeight: FontWeight.w700,
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
                          if ((ride.assignedAdminName ?? '').isNotEmpty)
                            Text(
                              'Assigned Admin: ${ride.assignedAdminName}',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          if ((ride.assignmentMethod ?? '').isNotEmpty)
                            Text(
                              'Assignment: ${ride.assignmentMethod}',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          if (ride.activeAdminLoad != null)
                            Text(
                              'Admin Load Snapshot: ${ride.activeAdminLoad}',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          if (ride.driver != null)
                            Text(
                              'Driver: ${ride.driver}',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          if (ride.orderId != null && ride.orderId!.isNotEmpty)
                            Text(
                              'Order: ${ride.orderId}',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          if (ride.note.isNotEmpty)
                            Text(
                              'Note: ${ride.note}',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusButton(ride.id, 'searching'),
                              _statusButton(ride.id, 'on_the_way'),
                              _statusButton(
                                ride.id,
                                isDelivery ? 'delivery_in_progress' : 'ride_in_progress',
                              ),
                              _statusButton(ride.id, 'completed'),
                              _statusButton(ride.id, 'cancelled'),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DriverModeScreen(
                                        ride: ride,
                                        driverName: ride.driver ?? 'Musa',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(isDelivery ? 'Delivery Mode' : 'Driver Mode'),
                              ),
                              if (isSuperAdmin)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminReassignmentScreen(ride: ride),
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
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _statusButton(String rideId, String status) {
    return ElevatedButton(
      onPressed: () async {
        await firebaseService.updateRideStatus(
          rideId: rideId,
          status: status,
        );
      },
      child: Text(status),
    );
  }
}
