// ── ISMAILTEX Payment Config Model ────────────────────────────────────────────
// Removed ride-specific fare fields.
// Added textile delivery fee configuration.

class PaymentConfigModel {
  final bool paystackEnabled;
  final String activeGateway;
  final List<String> enabledGateways;
  final String paystackPublicKey;

  // ── Textile Delivery Pricing ─────────────────────────────────────────────────
  final double deliveryBaseFee;
  final double deliveryFeePerKm;
  final double freeDeliveryThreshold;

  // ── Order Settings ───────────────────────────────────────────────────────────
  final double minimumOrderAmount;
  final double maximumCouponDiscount;

  const PaymentConfigModel({
    required this.paystackEnabled,
    required this.activeGateway,
    required this.enabledGateways,
    required this.paystackPublicKey,
    required this.deliveryBaseFee,
    required this.deliveryFeePerKm,
    required this.freeDeliveryThreshold,
    required this.minimumOrderAmount,
    required this.maximumCouponDiscount,
  });

  factory PaymentConfigModel.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};

    return PaymentConfigModel(
      paystackEnabled:
          (data['paystackEnabled'] ?? true) == true,
      activeGateway:
          (data['activeGateway'] ?? 'paystack').toString(),
      enabledGateways: List<String>.from(
        data['enabledGateways'] ?? const ['paystack'],
      ),
      paystackPublicKey:
          (data['paystackPublicKey'] ?? '').toString().trim(),

      // ── Delivery fee config ──────────────────────────────────
      // Default: ₦500 base + ₦50 per km, free delivery above ₦15,000
      deliveryBaseFee:
          ((data['deliveryBaseFee'] ?? 500) as num).toDouble(),
      deliveryFeePerKm:
          ((data['deliveryFeePerKm'] ?? 50) as num).toDouble(),
      freeDeliveryThreshold:
          ((data['freeDeliveryThreshold'] ?? 15000) as num)
              .toDouble(),

      // ── Order config ─────────────────────────────────────────
      minimumOrderAmount:
          ((data['minimumOrderAmount'] ?? 1000) as num).toDouble(),
      maximumCouponDiscount:
          ((data['maximumCouponDiscount'] ?? 5000) as num)
              .toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paystackEnabled': paystackEnabled,
      'activeGateway': activeGateway,
      'enabledGateways': enabledGateways,
      'paystackPublicKey': paystackPublicKey,
      'deliveryBaseFee': deliveryBaseFee,
      'deliveryFeePerKm': deliveryFeePerKm,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumCouponDiscount': maximumCouponDiscount,
    };
  }

  /// Calculate delivery fee for a given order subtotal.
  /// Returns 0 if subtotal qualifies for free delivery.
  double calculateDeliveryFee(double orderSubtotal) {
    if (orderSubtotal >= freeDeliveryThreshold) return 0.0;
    return deliveryBaseFee;
  }

  /// Returns true if the order qualifies for free delivery.
  bool qualifiesForFreeDelivery(double orderSubtotal) {
    return orderSubtotal >= freeDeliveryThreshold;
  }

  /// Returns a human-readable free delivery threshold string.
  String get freeDeliveryLabel =>
      'Free delivery on orders above ₦${freeDeliveryThreshold.toStringAsFixed(0)}';
}
