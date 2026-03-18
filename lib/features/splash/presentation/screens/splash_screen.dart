import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mix/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mix/features/auth/presentation/screens/login_screen.dart';
import 'package:mix/features/products/presentation/screens/product_list_screen.dart';

const String kAdminUid = 'PUT_ADMIN_UID_HERE';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 6));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    Widget next;
    if (user == null) {
      next = const LoginScreen();
    } else if (user.uid == kAdminUid) {
      next = AdminDashboardScreen();
    } else {
      next = ProductListScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF2A0A12);
    const orange = Color(0xFFFF7A18);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  wine,
                  Color(0xFF4B0D1F),
                  Color(0xFF12060A),
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -50,
            child: _GlowBlob(
              diameter: 260,
              color: const Color(0xFFFFD166).withOpacity(0.45),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -70,
            child: _GlowBlob(
              diameter: 280,
              color: const Color(0xFFB80F2B).withOpacity(0.42),
            ),
          ),
          Positioned(
            top: 180,
            right: -40,
            child: _GlowBlob(
              diameter: 200,
              color: orange.withOpacity(0.28),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                          border: Border.all(color: Colors.white24),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.25),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'M',
                            style: GoogleFonts.playfairDisplay(
                              color: gold,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mix',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Maamah's Mix",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Premium African spices, flours & traditional foods',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
