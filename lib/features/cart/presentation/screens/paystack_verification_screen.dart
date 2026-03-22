import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/models/payment_session_model.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:mix/services/payment_service.dart';

class PaystackVerificationScreen extends StatefulWidget {
  final PaymentSessionModel session;

  const PaystackVerificationScreen({
    super.key,
    required this.session,
  });

  @override
  State<PaystackVerificationScreen> createState() =>
      _PaystackVerificationScreenState();
}

class _PaystackVerificationScreenState
    extends State<PaystackVerificationScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _verifying = false;
  String? _statusText;

  Future<void> _verifyNow() async {
    if (_verifying) return;

    setState(() {
      _verifying = true;
      _statusText = null;
    });

    try {
      final attempt =
          await _paymentService.getPaymentAttempt(widget.session.reference);

      if (attempt == null) {
        setState(() {
          _statusText = 'Payment attempt not found. Please try again.';
        });
        return;
      }

      await _paymentService.confirmManualPaymentSuccess(widget.session);

      await _firebaseService.placeOrder(widget.session.items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed. Order placed successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Verification failed: $e';
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F5EF);
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M',
                  style: GoogleFonts.cinzel(
                    color: wine,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Verify Payment',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: gold,
                  size: 42,
                ),
                const SizedBox(height: 14),
                Text(
                  'Complete Your Payment',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'After completing payment in Paystack, come back here and tap the button below to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference: ${widget.session.reference}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Amount: ₦${widget.session.amountNaira.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_statusText != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _statusText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verifyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E2121),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'I Have Completed Payment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
