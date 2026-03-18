import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:mix/services/firebase_service.dart';

class AdminRidesScreen extends StatelessWidget {
  AdminRidesScreen({super.key});

  final firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        title: Text(
          'Manage Rides',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: firebaseService.watchAllRides(),
        builder: (context, snapshot) {
          final rides = snapshot.data ?? [];

          if (rides.isEmpty) {
            return Center(
              child: Text(
                'No rides yet',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (_, i) {
              final ride = rides[i];

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
                      Text(
                        'Ride ID: ${ride.id}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'User: ${ride.userId}',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                        'Status: ${ride.status}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFC29B40),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (ride.driver != null)
                        Text(
                          'Driver: ${ride.driver}',
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
                          _assignDriverButton(ride.id, 'Musa', '5 mins'),
                          _assignDriverButton(ride.id, 'Ibrahim', '8 mins'),
                          _statusButton(ride.id, 'on_the_way'),
                          _statusButton(ride.id, 'ride_in_progress'),
                          _statusButton(ride.id, 'completed'),
                          _statusButton(ride.id, 'cancelled'),
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

  Widget _assignDriverButton(String rideId, String driver, String eta) {
    return ElevatedButton(
      onPressed: () async {
        await firebaseService.updateRideStatus(
          rideId: rideId,
          status: 'driver_assigned',
          driver: driver,
          eta: eta,
        );
      },
      child: Text('Assign $driver'),
    );
  }
}
