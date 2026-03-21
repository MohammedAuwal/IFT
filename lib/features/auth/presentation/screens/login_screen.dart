import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/cart/presentation/screens/cart_screen.dart';
import 'package:mix/features/orders/presentation/screens/order_screen.dart';
import 'package:mix/features/profile/presentation/screens/profile_screen.dart';
import 'package:mix/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:mix/services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectTo;

  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _goAfterLogin() async {
    if (!mounted) return;

    switch (widget.redirectTo) {
      case RouteNames.redirectCart:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CartScreen()),
          (route) => false,
        );
        return;
      case RouteNames.redirectOrders:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => OrderScreen()),
          (route) => false,
        );
        return;
      case RouteNames.redirectProfile:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (route) => false,
        );
        return;
      case RouteNames.redirectRider:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
          (route) => false,
        );
        return;
      case RouteNames.redirectMainShell:
      default:
        await AppRouter.clearAndGo(context, RouteNames.mainShell);
        return;
    }
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email and password are required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      await _goAfterLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                themeController.toggleDarkMode(!themeController.isDarkMode),
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withOpacity(0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.12),
                      blurRadius: 24,
                      spreadRadius: 1,
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
                    child: Center(
                      child: Text(
                        'M',
                        style: GoogleFonts.cinzel(
                          color: wine,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                "Maamah's Mix",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.redirectTo == null
                    ? 'Sign in to manage your rides, deliveries, orders and favorites'
                    : 'Sign in to continue where you stopped',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
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
                children: [
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E2121),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Continue as Guest',
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
        ),
      ),
    );
  }
}
