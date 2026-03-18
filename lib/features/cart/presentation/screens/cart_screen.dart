import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/services/firebase_service.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

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
          'My Cart',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.watchCart(),
        builder: (context, snapshot) {
          final cartItems = snapshot.data ?? [];

          final total = cartItems.fold<double>(
            0,
            (sum, item) =>
                sum + (((item['price'] ?? 0) as num).toDouble() * ((item['qty'] ?? 1) as int)),
          );

          if (cartItems.isEmpty) {
            return Center(
              child: Text(
                'Your cart is empty',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (_, i) {
                    final item = cartItems[i];
                    final qty = (item['qty'] ?? 1) as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              (item['imageUrl'] ?? '').toString(),
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFFC29B40),
                                child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '₦${((item['price'] ?? 0) as num).toDouble().toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await firebaseService.updateCartQty(
                                    productId: item['productId'],
                                    qty: qty - 1,
                                  );
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$qty',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await firebaseService.updateCartQty(
                                    productId: item['productId'],
                                    qty: qty + 1,
                                  );
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
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
                        onPressed: () async {
                          await firebaseService.placeOrder(cartItems);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order placed successfully')),
                            );
                            Navigator.of(context).pop();
                          }
                        },
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
          );
        },
      ),
    );
  }
}
