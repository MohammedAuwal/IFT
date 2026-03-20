import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/features/rider/presentation/screens/ride_estimate_map_preview_screen.dart';
import 'package:mix/services/firebase_service.dart';

class CartScreen extends StatefulWidget {
  final bool showScaffold;

  const CartScreen({super.key, this.showScaffold = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseService firebaseService = FirebaseService();

  bool _loadingDeliveryEstimate = false;
  String? _deliveryEstimateError;
  MovementEstimate? _deliveryEstimate;
  String _lastEstimatedAddress = '';
  String _vendorPickupAddress = '';

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _estimateDelivery(String selectedAddress) async {
    if (selectedAddress.trim().isEmpty) {
      setState(() {
        _deliveryEstimate = null;
        _deliveryEstimateError =
            'Please select a saved delivery address before checkout';
      });
      return;
    }

    setState(() {
      _loadingDeliveryEstimate = true;
      _deliveryEstimateError = null;
    });

    try {
      final vendorPickup = await firebaseService.getVendorPickupAddress();

      final estimate = await firebaseService.estimateMovement(
        type: 'delivery',
        pickup: vendorPickup,
        destination: selectedAddress,
      );

      if (!mounted) return;
      setState(() {
        _deliveryEstimate = estimate;
        _lastEstimatedAddress = selectedAddress;
        _vendorPickupAddress = vendorPickup;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deliveryEstimate = null;
        _deliveryEstimateError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingDeliveryEstimate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.watchCart(),
      builder: (context, snapshot) {
        final cartItems = snapshot.data ?? [];

        final total = cartItems.fold<double>(
          0,
          (sum, item) =>
              sum +
              (((item['price'] ?? 0) as num).toDouble() *
                  ((item['qty'] ?? 1) as int)),
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
                  final imageUrl = (item['imageUrl'] ?? '').toString();

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
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: _hasValidImage(imageUrl)
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Color(0xFFC29B40),
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFFC29B40),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['name'] ?? '').toString(),
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
                                  productId: item['productId'].toString(),
                                  qty: qty - 1,
                                );
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$qty',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await firebaseService.updateCartQty(
                                  productId: item['productId'].toString(),
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
            StreamBuilder<String>(
              stream: firebaseService.watchSelectedAddress(),
              builder: (context, addressSnapshot) {
                final selectedAddress = addressSnapshot.data ?? '';

                if (_lastEstimatedAddress != selectedAddress &&
                    _deliveryEstimate != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _deliveryEstimate = null;
                      _deliveryEstimateError = null;
                    });
                  });
                }

                final deliveryFee = _deliveryEstimate?.price ?? 0;
                final grandTotal = total + deliveryFee;

                return Container(
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
                            'Delivery Address',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              selectedAddress.isEmpty
                                  ? 'Not selected'
                                  : selectedAddress,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: selectedAddress.isEmpty
                                    ? Colors.redAccent
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_deliveryEstimateError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _deliveryEstimateError!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (_deliveryEstimate != null)
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
                                'Delivery Estimate',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7A5A12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vendor Pickup: ${_deliveryEstimate!.pickupLabel}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Destination: ${_deliveryEstimate!.destinationLabel}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Distance: ${_deliveryEstimate!.distanceKm.toStringAsFixed(1)} km',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'ETA: ${_deliveryEstimate!.eta}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Delivery Fee: ₦${_deliveryEstimate!.price.toStringAsFixed(0)}',
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
                                        builder: (_) =>
                                            RideEstimateMapPreviewScreen(
                                          estimate: _deliveryEstimate!,
                                          title: 'Delivery Route Preview',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Preview Delivery Route'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loadingDeliveryEstimate
                                  ? null
                                  : () => _estimateDelivery(selectedAddress),
                              child: _loadingDeliveryEstimate
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Check Delivery'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Items Total',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₦${total.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Delivery Fee',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _deliveryEstimate == null
                                ? 'Check estimate'
                                : '₦${deliveryFee.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _deliveryEstimate == null
                                  ? Colors.black45
                                  : const Color(0xFFC29B40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Grand Total',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₦${grandTotal.toStringAsFixed(2)}',
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
                            try {
                              await firebaseService.placeOrder(cartItems);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Order placed successfully. Delivery created with live route.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Checkout failed: $e'),
                                  ),
                                );
                              }
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
                            style:
                                GoogleFonts.poppins(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    if (!widget.showScaffold) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F5EF),
        body: SafeArea(child: content),
      );
    }

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
      body: content,
    );
  }
}
