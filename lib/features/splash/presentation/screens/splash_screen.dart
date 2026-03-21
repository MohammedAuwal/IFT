import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  bool _navigated = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await Future.any([
        _bootstrap(),
        Future.delayed(const Duration(seconds: 12), () {
          throw Exception('App startup timed out. Please try again.');
        }),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
      });
    }
  }

  Future<void> _bootstrap() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _firebaseService.ensureUserProfile();
    }

    final isAdmin = user != null ? await _firebaseService.isAdmin() : false;

    if (!mounted || _navigated) return;
    _navigated = true;

    if (user == null) {
      await AppRouter.clearAndGo(context, RouteNames.login);
      return;
    }

    if (isAdmin) {
      await AppRouter.clearAndGo(context, RouteNames.admin);
      return;
    }

    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _retry() async {
    setState(() {
      _errorText = null;
      _navigated = false;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2A0A12);
    const gold = Color(0xFFC29B40);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _errorText == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          color: gold,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        "Maamah's Mix",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Food, products, rides & delivery in one app',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const CircularProgressIndicator(
                        color: gold,
                        strokeWidth: 2.6,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 14),
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
    );
  }
}
