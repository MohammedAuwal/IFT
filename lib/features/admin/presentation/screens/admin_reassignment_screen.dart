import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/models/order_model.dart';
import 'package:mix/models/ride_model.dart';
import 'package:mix/services/firebase_service.dart';

class AdminReassignmentScreen extends StatelessWidget {
  final RideModel? ride;
  final OrderModel? order;

  AdminReassignmentScreen({
    super.key,
    this.ride,
    this.order,
  }) : assert(ride != null || order != null);

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _reassignTo(
    BuildContext context,
    Map<String, dynamic> admin,
  ) async {
    final uid = (admin['uid'] ?? '').toString();
    final email = (admin['email'] ?? '').toString();
    final name = (admin['displayName'] ?? email).toString();

    if (uid.isEmpty) return;

    if (ride != null) {
      await _firebaseService.reassignRideToAdmin(
        rideId: ride!.id,
        adminUid: uid,
        adminName: name,
        adminEmail: email,
      );
    }

    if (order != null) {
      await _firebaseService.reassignOrderToAdmin(
        orderId: order!.id,
        adminUid: uid,
        adminName: name,
        adminEmail: email,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request reassigned successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);

    final title = ride != null
        ? (ride!.type == 'delivery' ? 'Reassign Delivery' : 'Reassign Ride')
        : 'Reassign Order';

    final subtitle = ride != null
        ? '${ride!.pickup} → ${ride!.destination}'
        : order!.deliveryAddress;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.watchAdmins(),
        builder: (context, snapshot) {
          final admins = snapshot.data ?? [];

          if (admins.isEmpty) {
            return Center(
              child: Text(
                'No admins available',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Choose Admin',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...admins.map((admin) {
                final displayName =
                    (admin['displayName'] ?? admin['email'] ?? '').toString();
                final email = (admin['email'] ?? '').toString();
                final baseAddress = (admin['baseAddress'] ?? '').toString();
                final isActive = (admin['isActive'] ?? true) == true;
                final maxLoad =
                    ((admin['maxActiveAssignments'] ?? 20) as num).toInt();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    title: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        if (baseAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              baseAddress,
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isActive
                                ? 'Active • Max load: $maxLoad'
                                : 'Paused • Max load: $maxLoad',
                            style: GoogleFonts.poppins(
                              color: isActive
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _reassignTo(context, admin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        'Assign',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
