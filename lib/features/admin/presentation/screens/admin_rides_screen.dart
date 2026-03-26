import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/core/theme/app_theme.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:mix/features/rider/presentation/screens/driver_mode_screen.dart';
import 'package:mix/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class AdminRidesScreen extends StatelessWidget {
  AdminRidesScreen({super.key});

  final firebaseService = FirebaseService();

  Color _statusColor(BuildContext context, String status) {
    final colors = AppTheme.colorsOf(context);

    switch (status) {
      case 'completed':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'ride_in_progress':
      case 'delivery_in_progress':
        return colors.info;
      case 'on_the_way':
        return colors.warning;
      default:
        return colors.brandPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final colors = AppTheme.colorsOf(context);

    return FutureBuilder<bool>(
      future: firebaseService.isAdmin(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: colors.scaffold,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = adminSnapshot.data ?? false;
        final isSuperAdmin =
            FirebaseAuth.instance.currentUser?.uid == AppConstants.superAdminUid;

        if (!isAdmin && !isSuperAdmin) {
          return Scaffold(
            backgroundColor: colors.scaffold,
            appBar: AppBar(
              title: Text(
                'Manage Rides & Deliveries',
                style: GoogleFonts.poppins(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: Center(
              child: Text(
                'You do not have access to rides',
                style: GoogleFonts.poppins(color: colors.textSecondary),
              ),
            ),
          );
        }

        final stream = isSuperAdmin
            ? firebaseService.watchAllRides()
            : firebaseService.watchAssignedRidesForAdmin();

        return Scaffold(
          backgroundColor: colors.scaffold,
          appBar: AppBar(
            title: Text(
              isSuperAdmin
                  ? 'Manage All Rides & Deliveries'
                  : 'My Assigned Rides & Deliveries',
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
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
                  color: colors.iconPrimary,
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<RideModel>>(
            stream: stream,
            builder: (context, snapshot) {
              final rides = snapshot.data ?? [];

              if (rides.isEmpty) {
                return Center(
                  child: Text(
                    isSuperAdmin
                        ? 'No rides yet'
                        : 'No assigned rides yet',
                    style: GoogleFonts.poppins(color: colors.textSecondary),
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
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.borderSoft),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                  color: colors.textPrimary,
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
                                      ? colors.info.withOpacity(0.15)
                                      : colors.brandPrimary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isDelivery ? 'Delivery' : 'Ride',
                                  style: GoogleFonts.poppins(
                                    color: isDelivery
                                        ? colors.info
                                        : colors.brandPrimary,
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
                                    color: colors.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Escalated',
                                    style: GoogleFonts.poppins(
                                      color: colors.error,
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
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          Text(
                            'To: ${ride.destination}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ride Type: ${ride.rideType}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Distance: ${ride.distanceKm.toStringAsFixed(1)} km • ETA: ${ride.eta}',
                            style: GoogleFonts.poppins(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fare: ₦${ride.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              color: colors.brandPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status: ${ride.status}',
                            style: GoogleFonts.poppins(
                              color: _statusColor(context, ride.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((ride.assignedAdminName ?? '').isNotEmpty)
                            Text(
                              'Assigned Admin: ${ride.assignedAdminName}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          if ((ride.assignmentMethod ?? '').isNotEmpty)
                            Text(
                              'Assignment: ${ride.assignmentMethod}',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          if (ride.activeAdminLoad != null)
                            Text(
                              'Admin Load Snapshot: ${ride.activeAdminLoad}',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          if (ride.driver != null)
                            Text(
                              'Driver: ${ride.driver}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          if (ride.orderId != null && ride.orderId!.isNotEmpty)
                            Text(
                              'Order: ${ride.orderId}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          if (ride.note.isNotEmpty)
                            Text(
                              'Note: ${ride.note}',
                              style: GoogleFonts.poppins(color: colors.textSecondary),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusButton(context, ride.id, 'searching'),
                              _statusButton(context, ride.id, 'on_the_way'),
                              _statusButton(
                                context,
                                ride.id,
                                isDelivery ? 'delivery_in_progress' : 'ride_in_progress',
                              ),
                              _statusButton(context, ride.id, 'completed'),
                              _statusButton(context, ride.id, 'cancelled'),
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

  Widget _statusButton(BuildContext context, String rideId, String status) {
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
