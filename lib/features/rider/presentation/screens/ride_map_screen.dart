import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/models/ride_model.dart';

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
  List<LatLng> _decodeRoute(String geometry) {
    if (geometry.trim().isEmpty) return [];

    try {
      final map = jsonDecode(geometry) as Map<String, dynamic>;
      final coords = List<List<dynamic>>.from(map['coordinates'] ?? []);
      return coords
          .where((c) => c.length >= 2)
          .map(
            (c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  LatLngBounds? _boundsFor(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
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
        final ride =
            data != null ? RideModel.fromMap(widget.ride.id, data) : widget.ride;

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

        final routePoints = _decodeRoute(ride.routeGeometry);

        final allPoints = <LatLng>[
          if (pickup != null) pickup,
          if (destination != null) destination,
          if (driver != null) driver,
          ...routePoints,
        ];

        final center = pickup ??
            destination ??
            LatLng(
              AppConstants.nigeriaCenterLat,
              AppConstants.nigeriaCenterLng,
            );

        final bounds = _boundsFor(allPoints);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              ride.type == 'delivery' ? 'Delivery Map' : 'Ride Map',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 6,
                    initialCameraFit: bounds != null
                        ? CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(40),
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.maamahsmix.app',
                    ),
                    if (routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.deepOrange,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (pickup != null)
                          Marker(
                            point: pickup,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.green,
                              size: 36,
                            ),
                          ),
                        if (destination != null)
                          Marker(
                            point: destination,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                          ),
                        if (driver != null)
                          Marker(
                            point: driver,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.local_taxi,
                              color: Colors.amber,
                              size: 36,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${ride.status}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pickup: ${ride.pickup}',
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      'Destination: ${ride.destination}',
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      'Distance: ${ride.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      'ETA: ${ride.eta}',
                      style: GoogleFonts.poppins(),
                    ),
                    if (ride.driver != null)
                      Text(
                        'Driver: ${ride.driver}',
                        style: GoogleFonts.poppins(),
                      ),
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
