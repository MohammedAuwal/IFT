import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/services/firebase_service.dart';

class OrderScreen extends StatelessWidget {
  OrderScreen({super.key});

  final firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: firebaseService.watchOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No orders yet',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i];
              final isDelivered = order.status == 'delivered';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDelivered
                          ? Colors.green.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: isDelivered ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.status,
                            style: GoogleFonts.poppins(
                              color: isDelivered ? Colors.green : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₦${order.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC29B40),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
