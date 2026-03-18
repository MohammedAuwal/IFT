import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderScreen extends StatelessWidget {
  OrderScreen({super.key});

  final List<Map<String, dynamic>> orders = const [
    {
      'id': 'ORD-1001',
      'status': 'Processing',
      'amount': 10500.0,
    },
    {
      'id': 'ORD-1002',
      'status': 'Delivered',
      'amount': 5400.0,
    },
  ];

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
      body: orders.isEmpty
          ? Center(
              child: Text(
                'No orders yet',
                style: GoogleFonts.poppins(),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final order = orders[i];
                final isDelivered = order['status'] == 'Delivered';

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
                              order['id'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order['status'],
                              style: GoogleFonts.poppins(
                                color: isDelivered ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₦${(order['amount'] as double).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC29B40),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
