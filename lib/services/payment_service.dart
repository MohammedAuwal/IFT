import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:mix/core/constants/app_constants.dart';

class PaymentResult {
  final bool success;
  final String reference;
  final String message;

  const PaymentResult({
    required this.success,
    required this.reference,
    required this.message,
  });
}

class PaymentService {
  PaymentService() {
    PaystackPlugin.initialize(
      publicKey: AppConstants.paystackPublicKey,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateReference() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'MIX_${now}_$random';
  }

  Future<PaymentResult> chargeCart({
    required BuildContext context,
    required String email,
    required double amountNaira,
    String? reference,
    String currency = 'NGN',
    Map<String, dynamic>? metadata,
  }) async {
    final paymentReference = reference ?? generateReference();

    final charge = Charge()
      ..amount = (amountNaira * 100).round()
      ..reference = paymentReference
      ..email = email
      ..currency = currency
      ..metadata = metadata ?? {};

    final response = await PaystackPlugin.checkout(
      context,
      charge: charge,
      method: CheckoutMethod.card,
      fullscreen: true,
      logo: const _PaystackLogoPlaceholder(),
    );

    if (response.status == true) {
      await _firestore
          .collection(AppConstants.paymentsCollection)
          .doc(paymentReference)
          .set({
        'reference': paymentReference,
        'status': 'success',
        'gateway': 'paystack',
        'amountNaira': amountNaira,
        'currency': currency,
        'email': email,
        'gatewayMessage': response.message ?? 'Payment successful',
        'verified': true,
        'createdAt': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      }, SetOptions(merge: true));

      return PaymentResult(
        success: true,
        reference: paymentReference,
        message: response.message ?? 'Payment successful',
      );
    }

    await _firestore
        .collection(AppConstants.paymentsCollection)
        .doc(paymentReference)
        .set({
      'reference': paymentReference,
      'status': 'failed',
      'gateway': 'paystack',
      'amountNaira': amountNaira,
      'currency': currency,
      'email': email,
      'gatewayMessage': response.message ?? 'Payment was not completed',
      'verified': false,
      'createdAt': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    }, SetOptions(merge: true));

    return PaymentResult(
      success: false,
      reference: paymentReference,
      message: response.message ?? 'Payment was not completed',
    );
  }
}

class _PaystackLogoPlaceholder extends StatelessWidget {
  const _PaystackLogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
