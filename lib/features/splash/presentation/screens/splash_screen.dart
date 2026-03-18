import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/services/connectivity_service.dart';
import 'package:mix/services/firebase_service.dart';

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

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _navigated = false;

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
    _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Step 1: Check internet
      final hasInternet = await ConnectivityService.hasInternet();

      if (!hasInternet) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Poor network connection.\nPlease check your internet.';
        });
        return;
      }

      // Step 2: Initialize Firebase with timeout
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Firebase initialization timed out');
        },
      );

      // Step 3: Minimum splash display for branding
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Step 4: Navigate based on auth
      await _resolveNavigation();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Connection timed out.\nPlease try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Something went wrong.\nPlease try again.';
      });
    }
  }

  Future<void> _resolveNavigation() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;

    // Not logged in → Login
    if (user == null) {
      await AppRouter.clearAndGo(context, RouteNames.login);
      return;
    }

    // Logged in → setup profile and sync cart (non-critical)
    try {
      await firebaseService.ensureUserProfile().timeout(
            const Duration(seconds: 5),
          );
      await firebaseService.syncLocalCartToFirestore().timeout(
            const Duration(seconds: 5),
          );
    } catch (_) {
      // Non-critical — continue even if these fail
    }

    if (!mounted) return;

    // Check admin status
    try {
      final isAdmin = await firebaseService.isAdmin().timeout(
            const Duration(seconds: 5),
          );

      if (!mounted) return;

      if (isAdmin) {
        await AppRouter.clearAndGo(context, RouteNames.admin);
      } else {
        await AppRouter.clearAndGo(context, RouteNames.mainShell);
      }
    } catch (_) {
      // Default to main shell if admin check fails
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    }
  }

  void _retry() {
    _navigated = false;
    _initialize();
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
          // Background gradient
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

          // Glow blobs
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

          // Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo circle with M
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

                      // Mix title
                      Text(
                        'Mix',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Maamah's Mix
                      Text(
                        "Maamah's Mix",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Premium African spices, flours & traditional foods',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Loading or Error section
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _hasError
                            ? _buildErrorWidget(gold)
                            : _isLoading
                                ? _buildLoadingWidget(gold)
                                : const SizedBox.shrink(),
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

  Widget _buildLoadingWidget(Color gold) {
    return SizedBox(
      key: const ValueKey('loading'),
      width: 42,
      height: 42,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(gold),
      ),
    );
  }

  Widget _buildErrorWidget(Color gold) {
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wifi off icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
        ),
        const SizedBox(height: 16),

        // Error message
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Retry button
        GestureDetector(
          onTap: _retry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  gold,
                  gold.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
