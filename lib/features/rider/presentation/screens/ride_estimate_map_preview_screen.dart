import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/services/firebase_service.dart';

class RideEstimateMapPreviewScreen extends StatelessWidget {
  final MovementEstimate estimate;
  final String title;

  const RideEstimateMapPreviewScreen({
    super.key,
    required this.estimate,
    this.title = 'Route Preview',
  });

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
    final routePoints = _decodeRoute(estimate.routeGeometry);
    final pickup = LatLng(estimate.pickupLat, estimate.pickupLng);
    final destination = LatLng(estimate.destinationLat, estimate.destinationLng);

    final points = <LatLng>[
      pickup,
      destination,
      ...routePoints,
    ];

    final bounds = _boundsFor(points);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: pickup,
                initialZoom: 6,
                initialCameraFit: bounds != null
                    ? CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(36),
                      )
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup: ${estimate.pickupLabel}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Destination: ${estimate.destinationLabel}',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance: ${estimate.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.poppins(),
                ),
                Text(
                  'ETA: ${estimate.eta}',
                  style: GoogleFonts.poppins(),
                ),
                Text(
                  'Estimated Fare: ₦${estimate.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC29B40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
