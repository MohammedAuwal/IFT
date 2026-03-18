import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/location_service.dart';

class RideMapScreen extends StatefulWidget {
  final RideModel ride;

  const RideMapScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  final _locationService = LocationService();
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final loc = await _locationService.getCurrentLatLng();
    if (!mounted) return;
    setState(() => _currentUserLocation = loc);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.ridesCollection)
          .doc(widget.ride.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final ride = data != null ? RideModel.fromMap(widget.ride.id, data) : widget.ride;

        final pickup = (ride.pickupLat != null && ride.pickupLng != null)
            ? LatLng(ride.pickupLat!, ride.pickupLng!)
            : null;

        final destination =
            (ride.destinationLat != null && ride.destinationLng != null)
                ? LatLng(ride.destinationLat!, ride.destinationLng!)
                : null;

        final driver = (ride.driverLat != null && ride.driverLng != null)
            ? LatLng(ride.driverLat!, ride.driverLng!)
            : null;

        final center = driver ?? pickup ?? _currentUserLocation ?? LatLng(9.0765, 7.3986);

        final markers = <Marker>[
          if (pickup != null)
            Marker(
              point: pickup,
              width: 44,
              height: 44,
              child: const Icon(Icons.my_location, color: Colors.green, size: 36),
            ),
          if (destination != null)
            Marker(
              point: destination,
              width: 44,
              height: 44,
              child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
            ),
          if (driver != null)
            Marker(
              point: driver,
              width: 44,
              height: 44,
              child: const Icon(Icons.local_taxi, color: Colors.amber, size: 36),
            ),
          if (_currentUserLocation != null)
            Marker(
              point: _currentUserLocation!,
              width: 32,
              height: 32,
              child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 30),
            ),
        ];

        final polylinePoints = <LatLng>[
          if (pickup != null) pickup,
          if (driver != null) driver,
          if (destination != null) destination,
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Ride Map',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.maamahsmix.app',
                    ),
                    if (polylinePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: polylinePoints,
                            color: Colors.deepOrange,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${ride.status}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Pickup: ${ride.pickup}', style: GoogleFonts.poppins()),
                    Text('Destination: ${ride.destination}', style: GoogleFonts.poppins()),
                    if (ride.driver != null)
                      Text('Driver: ${ride.driver}', style: GoogleFonts.poppins()),
                    if (ride.eta.isNotEmpty)
                      Text('ETA: ${ride.eta}', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
