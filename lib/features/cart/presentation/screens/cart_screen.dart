import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final List<Map<String, dynamic>> cartItems = [
    {
      'name': 'Ground Pepper',
      'price': 2500.0,
      'qty': 1,
    },
    {
      'name': 'Maize Flour',
      'price': 4000.0,
      'qty': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final total = cartItems.fold<double>(
      0,
      (sum, item) => sum + ((item['price'] as double) * (item['qty'] as int)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'My Cart',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Text(
                'Your cart is empty',
                style: GoogleFonts.poppins(),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (_, i) {
                      final item = cartItems[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFC29B40),
                              child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₦${(item['price'] as double).toStringAsFixed(2)} x ${item['qty']}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₦${((item['price'] as double) * (item['qty'] as int)).toStringAsFixed(2)}',
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
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₦${total.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: const Color(0xFFC29B40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E2121),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Proceed to Checkout',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
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
