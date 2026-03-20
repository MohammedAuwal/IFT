import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:mix/features/rider/presentation/screens/ride_estimate_map_preview_screen.dart';
import 'package:mix/features/rider/presentation/screens/ride_map_screen.dart';
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
  bool _loadingEstimate = false;
  bool _bookingRide = false;
  String? _estimateError;
  MovementEstimate? _estimate;

  Future<void> _estimateRide() async {
    final pickup = _pickupCtrl.text.trim();
    final destination = _destinationCtrl.text.trim();

    if (pickup.isEmpty || destination.isEmpty) {
      setState(() {
        _estimateError = 'Pickup and destination are required';
        _estimate = null;
      });
      return;
    }

    setState(() {
      _loadingEstimate = true;
      _estimateError = null;
    });

    try {
      final result = await firebaseService.estimateMovement(
        type: 'ride',
        pickup: pickup,
        destination: destination,
      );

      if (!mounted) return;
      setState(() {
        _estimate = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estimate = null;
        _estimateError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingEstimate = false);
      }
    }
  }

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

    setState(() => _bookingRide = true);

    try {
      await firebaseService.createRide(
        pickup: pickup,
        destination: destination,
        rideType: _rideType,
        price: _estimate?.price ?? 0,
        note: note,
      );

      _pickupCtrl.clear();
      _destinationCtrl.clear();
      _noteCtrl.clear();

      setState(() {
        _estimateError = null;
        _estimate = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride booked successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _bookingRide = false);
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
              (r) => r.isActive && r.type == 'ride',
            );
          } catch (_) {
            activeRide = null;
          }

          final history = rides
              .where((r) => !r.isActive && r.type == 'ride')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeRide != null)
                _RideStatusCard(
                  ride: activeRide,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RideDetailScreen(ride: activeRide!),
                      ),
                    );
                  },
                  onOpenMap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RideMapScreen(ride: activeRide!),
                      ),
                    );
                  },
                  onCancel: () async {
                    await firebaseService.cancelRide(activeRide!.id);
                  },
                )
              else
                const EmptyStateCard(
                  icon: Icons.local_taxi_outlined,
                  title: 'No active ride',
                  subtitle: 'Book a ride to get moving quickly and safely anywhere in Nigeria.',
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
                      onChanged: (_) {
                        if (_estimate != null || _estimateError != null) {
                          setState(() {
                            _estimate = null;
                            _estimateError = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Pickup anywhere in Nigeria',
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
                      onChanged: (_) {
                        if (_estimate != null || _estimateError != null) {
                          setState(() {
                            _estimate = null;
                            _estimateError = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Destination anywhere in Nigeria',
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
                    if (_estimateError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _estimateError!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_estimate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F0E0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC29B40).withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Estimate',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7A5A12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pickup: ${_estimate!.pickupLabel}',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Destination: ${_estimate!.destinationLabel}',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Distance: ${_estimate!.distanceKm.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'ETA: ${_estimate!.eta}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Fare: ₦${_estimate!.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFFC29B40),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RideEstimateMapPreviewScreen(
                                        estimate: _estimate!,
                                        title: 'Ride Route Preview',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Preview Route on Map'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loadingEstimate ? null : _estimateRide,
                            child: _loadingEstimate
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Check Route'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: activeRide == null && !_bookingRide
                                  ? _bookRide
                                  : null,
                              icon: _bookingRide
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.local_taxi_rounded),
                              label: Text(
                                activeRide == null
                                    ? 'Confirm Ride'
                                    : 'Active Ride Exists',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ride History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (history.isEmpty)
                Text(
                  'No past rides yet',
                  style: GoogleFonts.poppins(color: Colors.black54),
                )
              else
                ...history.map(
                  (ride) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RideDetailScreen(ride: ride),
                          ),
                        );
                      },
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFC29B40),
                        child: Icon(Icons.history_rounded, color: Colors.white),
                      ),
                      title: Text(
                        '${ride.pickup} → ${ride.destination}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${ride.status} • ${ride.distanceKm.toStringAsFixed(1)} km • ${ride.eta}',
                        style: GoogleFonts.poppins(
                          color: ride.status == 'completed'
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      ),
                      trailing: Text(
                        '₦${ride.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: gold,
                        ),
                      ),
                    ),
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
  final VoidCallback onTap;
  final VoidCallback onOpenMap;

  const _RideStatusCard({
    required this.ride,
    required this.onCancel,
    required this.onTap,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivery = ride.type == 'delivery';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              isDelivery ? '📦 Delivery in Progress' : '🚗 Ride in Progress',
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
            const SizedBox(height: 6),
            Text(
              'Distance: ${ride.distanceKm.toStringAsFixed(1)} km',
              style: GoogleFonts.poppins(),
            ),
            Text(
              'ETA: ${ride.eta}',
              style: GoogleFonts.poppins(),
            ),
            if (ride.driver != null) ...[
              const SizedBox(height: 6),
              Text('Driver: ${ride.driver}', style: GoogleFonts.poppins()),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpenMap,
                    child: const Text('Open Map'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel Ride'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
