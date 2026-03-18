import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final firebaseService = FirebaseService();

  final _pickupCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _rideType = 'car';

  double get _estimatedPrice => _rideType == 'bike' ? 1500 : 2500;

  Future<void> _bookRide() async {
    final pickup = _pickupCtrl.text.trim();
    final destination = _destinationCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    if (pickup.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and destination are required')),
      );
      return;
    }

    try {
      await firebaseService.createRide(
        pickup: pickup,
        destination: destination,
        rideType: _rideType,
        price: _estimatedPrice,
        note: note,
      );

      _pickupCtrl.clear();
      _destinationCtrl.clear();
      _noteCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride booked successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destinationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC29B40);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Book a Ride',
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
          RideModel? activeRide;

          try {
            activeRide = rides.firstWhere(
              (r) => r.status != 'completed' && r.status != 'cancelled',
            );
          } catch (_) {
            activeRide = null;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeRide != null)
                _RideStatusCard(
                  ride: activeRide,
                  onCancel: () async {
                    await firebaseService.cancelRide(activeRide!.id);
                  },
                )
              else
                const EmptyStateCard(
                  icon: Icons.local_taxi_outlined,
                  title: 'No active ride',
                  subtitle: 'Book a ride to get moving quickly and safely.',
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Booking',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pickupCtrl,
                      decoration: InputDecoration(
                        hintText: 'Pickup location',
                        prefixIcon: const Icon(Icons.my_location_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationCtrl,
                      decoration: InputDecoration(
                        hintText: 'Destination',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Special note (optional)',
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ride Type',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Bike'),
                            selected: _rideType == 'bike',
                            onSelected: (_) => setState(() => _rideType = 'bike'),
                            selectedColor: gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Car'),
                            selected: _rideType == 'car',
                            onSelected: (_) => setState(() => _rideType = 'car'),
                            selectedColor: gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Estimated Price',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₦${_estimatedPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: activeRide == null ? _bookRide : null,
                        icon: const Icon(Icons.local_taxi_rounded),
                        label: Text(
                          activeRide == null ? 'Confirm Ride' : 'Active Ride Exists',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E2121),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RideStatusCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onCancel;

  const _RideStatusCard({
    required this.ride,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚗 Ride in Progress',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text('From: ${ride.pickup}', style: GoogleFonts.poppins()),
          Text('To: ${ride.destination}', style: GoogleFonts.poppins()),
          const SizedBox(height: 10),
          Text(
            'Status: ${ride.status}',
            style: GoogleFonts.poppins(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (ride.driver != null) ...[
            const SizedBox(height: 6),
            Text('Driver: ${ride.driver}', style: GoogleFonts.poppins()),
          ],
          if (ride.eta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('ETA: ${ride.eta}', style: GoogleFonts.poppins()),
          ],
          if (ride.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${ride.note}', style: GoogleFonts.poppins()),
          ],
          const SizedBox(height: 6),
          Text(
            'Fare: ₦${ride.price.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC29B40),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel Ride'),
            ),
          ),
        ],
      ),
    );
  }
}
