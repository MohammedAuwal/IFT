import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ift/config/routes/route_names.dart';
import 'package:ift/core/routing/app_router.dart';
import 'package:ift/core/theme/app_theme.dart';
import 'package:ift/features/cart/presentation/screens/cart_screen.dart';
import 'package:ift/features/orders/presentation/screens/order_screen.dart';
import 'package:ift/features/profile/presentation/screens/profile_screen.dart';
import 'package:ift/features/rider/presentation/screens/rider_home_screen.dart';
import 'package:ift/services/firebase_auth_service.dart';
import 'package:ift/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectTo;

  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseService _firebaseService = FirebaseService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;

  Future<void> _goAfterLogin() async {
    if (!mounted) return;

    try {
      await _firebaseService.ensureUserProfile();
      await _firebaseService.syncLocalCartToFirestore();
    } catch (_) {}

    bool isAdmin = false;
    try {
      isAdmin = await _firebaseService.isAdmin();
    } catch (_) {
      isAdmin = false;
    }

    if (!mounted) return;

    if (isAdmin) {
      await AppRouter.clearAndGo(context, RouteNames.admin);
      return;
    }

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
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (user == null) {
        throw AuthFailure('Login failed. Please try again.');
      }

      if (!mounted) return;
      await _goAfterLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        throw AuthFailure('Google sign-in did not complete.');
      }

      if (!mounted) return;
      await _goAfterLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _goToSignup() async {
    await AppRouter.clearAndGo(context, RouteNames.signup);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.scaffold,
              colors.surfaceAlt,
              colors.scaffold,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -80,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brandPrimary.withOpacity(0.22),
                  boxShadow: [
                    BoxShadow(
                      color: colors.brandPrimary.withOpacity(0.18),
                      blurRadius: 90,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.warning.withOpacity(0.16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.warning.withOpacity(0.14),
                      blurRadius: 80,
                      spreadRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              right: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brandSecondary.withOpacity(0.22),
                  boxShadow: [
                    BoxShadow(
                      color: colors.brandSecondary.withOpacity(0.18),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 42,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 110),
                          Text(
                            "Maamah's Mix",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: colors.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Premium African spices, flours & traditional foods',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            decoration: BoxDecoration(
                              color: colors.card.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: colors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: GoogleFonts.poppins(
                                    color: colors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.redirectTo == null
                                      ? 'Sign in to continue your premium shopping experience.'
                                      : 'Sign in to continue where you stopped.',
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _GlassField(
                                  controller: _emailCtrl,
                                  hint: 'Email address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _GlassField(
                                  controller: _passwordCtrl,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _login,
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
                                            'Sign in',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: colors.border,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      child: Text(
                                        'or',
                                        style: GoogleFonts.poppins(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: colors.border,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: OutlinedButton(
                                    onPressed: _googleLoading ? null : _loginWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: colors.surface.withOpacity(0.5),
                                    ),
                                    child: _googleLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colors.brandPrimary,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'G',
                                                style: GoogleFonts.poppins(
                                                  color: colors.textPrimary,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.poppins(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'New here?',
                                        style: GoogleFonts.poppins(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: _goToSignup,
                                        child: Text(
                                          'Create an account',
                                          style: GoogleFonts.poppins(
                                            color: colors.brandPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'By continuing, you agree to our Terms & Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _continueAsGuest,
                            child: Text(
                              'Continue as Guest',
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          cursorColor: colors.brandPrimary,
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: false,
            fillColor: Colors.transparent,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: colors.iconPrimary,
              size: 26,
            ),
            suffixIcon: suffix,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 24,
            ),
          ),
        ),
      ),
    );
  }
}
