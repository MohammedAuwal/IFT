import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;
  bool _booting = false;
  String? _errorText;

  late final AnimationController _introController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutBack,
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 1,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _introController.forward();
    _pulseController.repeat(reverse: true);

    _start();
  }

  Future<void> _start() async {
    if (_booting) return;
    _booting = true;

    try {
      await Future.any([
        _bootstrap(),
        Future.delayed(const Duration(seconds: 12), () {
          throw Exception('App startup timed out. Please try again.');
        }),
      ]);
    } catch (e) {
      if (!mounted) return;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission-denied') ||
          errorStr.contains('permission denied')) {
        await _safeNavigate(RouteNames.mainShell);
        return;
      }

      setState(() {
        _errorText = e.toString();
      });
    } finally {
      _booting = false;
    }
  }

  Future<void> _safeNavigate(String routeName) async {
    if (!mounted || _navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppRouter.clearAndGo(context, routeName);
    });
  }

  Future<void> _bootstrap() async {
    final firebaseService = FirebaseService();

    await firebaseService.seedDefaultAppSettings();
    await firebaseService.seedDefaultCategoriesIfMissing();

    final user = firebaseService.currentUser;

    if (user != null) {
      await firebaseService.ensureUserProfile();
      await firebaseService.syncLocalCartToFirestore();

      final isAdmin = await firebaseService.isAdmin();
      if (isAdmin) {
        await _safeNavigate(RouteNames.admin);
        return;
      }
    }

    await _safeNavigate(RouteNames.mainShell);
  }

  Future<void> _retry() async {
    setState(() {
      _errorText = null;
      _navigated = false;
    });
    await _start();
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const top = Color(0xFF2A0A12);
    const bottom = Color(0xFF12060A);
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    return Scaffold(
      backgroundColor: top,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [top, bottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _errorText == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 118,
                                height: 118,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withOpacity(0.15),
                                      blurRadius: 26,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: gold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          'M',
                                          style: GoogleFonts.cinzel(
                                            color: wine,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 16,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.85),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SlideTransition(
                              position: _textSlideAnimation,
                              child: Text(
                                "Maamah's Mix",
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SlideTransition(
                              position: _textSlideAnimation,
                              child: Text(
                                'Food, products, rides & delivery in one app',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.7, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: const CircularProgressIndicator(
                                color: gold,
                                strokeWidth: 2.6,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 118,
                              height: 118,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Unable to load app',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _errorText!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _retry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
