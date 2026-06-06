import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ift/config/routes/route_names.dart';
import 'package:ift/core/theme/app_theme.dart';
import 'package:ift/features/auth/presentation/screens/login_screen.dart';
import 'package:ift/features/cart/presentation/screens/paystack_verification_screen.dart';
import 'package:ift/features/rider/presentation/screens/ride_estimate_map_preview_screen.dart';
import 'package:ift/models/payment_session_model.dart';
import 'package:ift/services/firebase_service.dart';
import 'package:ift/services/payment_service.dart';

class CartScreen extends StatefulWidget {
  final bool showScaffold;

  const CartScreen({super.key, this.showScaffold = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final PaymentService paymentService = PaymentService();

  bool _loadingDeliveryEstimate = false;
  bool _processingCheckout = false;
  String? _deliveryEstimateError;
  MovementEstimate? _deliveryEstimate;
  String _lastEstimatedAddress = '';
  String _vendorPickupAddress = '';

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          redirectTo: RouteNames.redirectCart,
        ),
      ),
    );
  }

  Future<void> _showGuestCheckoutPrompt() async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final colors = AppTheme.colorsOf(ctx);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Sign in required',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                'Please sign in or create an account to continue with checkout and delivery tracking.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!go) return;
    await _goToLogin();
  }

  Future<void> _estimateDelivery(String selectedAddress) async {
    if (_isGuest) {
      await _showGuestCheckoutPrompt();
      return;
    }

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

  Future<void> _checkout(
    List<Map<String, dynamic>> cartItems,
    double grandTotal,
    double itemsTotal,
  ) async {
    if (_isGuest) {
      await _showGuestCheckoutPrompt();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.email ?? '').trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A valid signed-in email is required for payment'),
        ),
      );
      return;
    }

    if (_deliveryEstimate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check delivery estimate before checkout'),
        ),
      );
      return;
    }

    setState(() => _processingCheckout = true);

    try {
      final result = await paymentService.initializeCheckout(
        userUid: user.uid,
        email: user.email!,
        amountNaira: grandTotal,
        items: cartItems,
        metadata: {
          'type': 'cart_checkout',
          'userId': user.uid,
          'itemsCount': cartItems.length,
          'itemsTotal': itemsTotal,
          'deliveryFee': _deliveryEstimate!.price,
          'distanceKm': _deliveryEstimate!.distanceKm,
          'eta': _deliveryEstimate!.eta,
        },
      );

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }

      final opened = await paymentService.openCheckoutUrl(result.authorizationUrl);

      if (!opened) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Paystack checkout'),
          ),
        );
        return;
      }

      if (!mounted) return;

      final session = PaymentSessionModel(
        reference: result.reference,
        userUid: user.uid,
        email: user.email!,
        amountNaira: grandTotal,
        currency: 'NGN',
        items: cartItems,
        metadata: {
          'type': 'cart_checkout',
          'userId': user.uid,
          'itemsCount': cartItems.length,
          'itemsTotal': itemsTotal,
          'deliveryFee': _deliveryEstimate!.price,
          'distanceKm': _deliveryEstimate!.distanceKm,
          'eta': _deliveryEstimate!.eta,
        },
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaystackVerificationScreen(session: session),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

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
              style: GoogleFonts.poppins(color: colors.textPrimary),
            ),
          );
        }

        return StreamBuilder<String>(
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

            return CustomScrollView(
              slivers: [
                if (_isGuest)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.brandPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colors.brandPrimary.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: colors.brown,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are shopping as a guest. Sign in to complete checkout, save addresses, and track your orders.',
                                style: GoogleFonts.poppins(
                                  color: colors.brown,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final item = cartItems[i];
                        final qty = (item['qty'] ?? 1) as int;
                        final imageUrl = (item['imageUrl'] ?? '').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.borderSoft),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                              CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                colors.brandPrimary,
                                            child: const Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              colors.brandPrimary,
                                          child: const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item['name'] ?? '').toString(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₦${((item['price'] ?? 0) as num).toDouble().toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        color: colors.textSecondary,
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
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: colors.iconPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$qty',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await firebaseService.updateCartQty(
                                        productId: item['productId'].toString(),
                                        qty: qty + 1,
                                      );
                                    },
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: colors.iconPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: cartItems.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(color: colors.borderSoft),
                      ),
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
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              child: Text(
                                _isGuest
                                    ? 'Sign in required'
                                    : (selectedAddress.isEmpty
                                        ? 'Not selected'
                                        : selectedAddress),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: _isGuest || selectedAddress.isEmpty
                                      ? colors.error
                                      : colors.textSecondary,
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
                              color: colors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _deliveryEstimateError!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colors.error,
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
                              color: colors.paleOrange,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.brandPrimary.withOpacity(0.25),
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
                                    color: colors.brown,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vendor Pickup: ${_deliveryEstimate!.pickupLabel}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Destination: ${_deliveryEstimate!.destinationLabel}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Distance: ${_deliveryEstimate!.distanceKm.toStringAsFixed(1)} km',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'ETA: ${_deliveryEstimate!.eta}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Delivery Fee: ₦${_deliveryEstimate!.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: colors.brandPrimary,
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
                                            title:
                                                'Delivery Route Preview',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text(
                                      'Preview Delivery Route',
                                    ),
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isGuest
                                            ? 'Sign In to Estimate'
                                            : 'Check Delivery',
                                      ),
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
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₦${total.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.textPrimary,
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
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _deliveryEstimate == null
                                  ? (_isGuest ? 'Sign in first' : 'Check estimate')
                                  : '₦${deliveryFee.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _deliveryEstimate == null
                                    ? colors.textSecondary
                                    : colors.brandPrimary,
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
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₦${grandTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: colors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _processingCheckout
                                ? null
                                : () => _checkout(cartItems, grandTotal, total),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.brandSecondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _processingCheckout
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isGuest
                                        ? 'Sign In to Checkout'
                                        : 'Proceed to Checkout',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: content,
    );
  }

  bool get showScaffold => widget.showScaffold;
}
