import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
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
    final pickup = (widget.ride.pickupLat != null && widget.ride.pickupLng != null)
        ? LatLng(widget.ride.pickupLat!, widget.ride.pickupLng!)
        : null;

    final destination = (widget.ride.destinationLat != null &&
            widget.ride.destinationLng != null)
        ? LatLng(widget.ride.destinationLat!, widget.ride.destinationLng!)
        : null;

    final driver = (widget.ride.driverLat != null && widget.ride.driverLng != null)
        ? LatLng(widget.ride.driverLat!, widget.ride.driverLng!)
        : null;

    final center = pickup ?? _currentUserLocation ?? LatLng(9.0765, 7.3986);

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
                Text('Status: ${widget.ride.status}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Pickup: ${widget.ride.pickup}', style: GoogleFonts.poppins()),
                Text('Destination: ${widget.ride.destination}', style: GoogleFonts.poppins()),
                if (widget.ride.driver != null)
                  Text('Driver: ${widget.ride.driver}', style: GoogleFonts.poppins()),
                if (widget.ride.eta.isNotEmpty)
                  Text('ETA: ${widget.ride.eta}', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
