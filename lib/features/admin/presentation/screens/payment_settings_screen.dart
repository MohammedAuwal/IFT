import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/models/payment_config_model.dart';
import 'package:mix/services/payment_service.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final PaymentService _paymentService = PaymentService();

  final _rideBaseFareCtrl = TextEditingController();
  final _ridePricePerKmCtrl = TextEditingController();
  final _deliveryBaseFareCtrl = TextEditingController();
  final _deliveryPricePerKmCtrl = TextEditingController();
  final _paystackPublicKeyCtrl = TextEditingController();

  bool _paystackEnabled = true;
  bool _loading = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _paymentService.seedPaymentConfigIfMissing();
  }

  Future<void> _save() async {
    final rideBaseFare = double.tryParse(_rideBaseFareCtrl.text.trim());
    final ridePricePerKm =
        double.tryParse(_ridePricePerKmCtrl.text.trim());
    final deliveryBaseFare =
        double.tryParse(_deliveryBaseFareCtrl.text.trim());
    final deliveryPricePerKm =
        double.tryParse(_deliveryPricePerKmCtrl.text.trim());

    if (rideBaseFare == null ||
        ridePricePerKm == null ||
        deliveryBaseFare == null ||
        deliveryPricePerKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numeric pricing values'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _paymentService.updatePaymentConfig(
        paystackEnabled: _paystackEnabled,
        activeGateway: 'paystack',
        rideBaseFare: rideBaseFare,
        ridePricePerKm: ridePricePerKm,
        deliveryBaseFare: deliveryBaseFare,
        deliveryPricePerKm: deliveryPricePerKm,
        paystackPublicKey: _paystackPublicKeyCtrl.text.trim(),
        enabledGateways: ['paystack'],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment and pricing settings updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update settings: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _rideBaseFareCtrl.dispose();
    _ridePricePerKmCtrl.dispose();
    _deliveryBaseFareCtrl.dispose();
    _deliveryPricePerKmCtrl.dispose();
    _paystackPublicKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M',
                  style: GoogleFonts.cinzel(
                    color: wine,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payment & Pricing Settings',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                themeController.toggleDarkMode(!themeController.isDarkMode),
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: StreamBuilder<PaymentConfigModel>(
        stream: _paymentService.watchPaymentConfig(),
        builder: (context, snapshot) {
          final config = snapshot.data;

          if (config != null && !_seeded) {
            _seeded = true;
            _paystackEnabled = config.paystackEnabled;
            _rideBaseFareCtrl.text = config.rideBaseFare.toStringAsFixed(0);
            _ridePricePerKmCtrl.text = config.ridePricePerKm.toStringAsFixed(0);
            _deliveryBaseFareCtrl.text =
                config.deliveryBaseFare.toStringAsFixed(0);
            _deliveryPricePerKmCtrl.text =
                config.deliveryPricePerKm.toStringAsFixed(0);
            _paystackPublicKeyCtrl.text = config.paystackPublicKey;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Pricing & Payment Control',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update payment gateway behavior and pricing from one place. Users will use the latest values without requiring a full app update.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: gold,
                      value: _paystackEnabled,
                      onChanged: (value) {
                        setState(() => _paystackEnabled = value);
                      },
                      title: Text(
                        'Enable Paystack',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _paystackPublicKeyCtrl,
                      hint: 'Paystack public key',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _rideBaseFareCtrl,
                            hint: 'Ride base fare',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            controller: _ridePricePerKmCtrl,
                            hint: 'Ride / km',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: _deliveryBaseFareCtrl,
                            hint: 'Delivery base fare',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            controller: _deliveryPricePerKmCtrl,
                            hint: 'Delivery / km',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Save Settings',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF11141A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
