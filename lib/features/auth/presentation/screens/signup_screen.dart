import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/services/firebase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signup() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _goToLogin() async {
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const topGlow = Color(0xFFC9984B);
    const bgTop = Color(0xFF3B0916);
    const bgBottom = Color(0xFF19040A);
    const cardBorder = Color(0x4DFFFFFF);
    const buttonRed = Color(0xFFB32626);
    const accentGold = Color(0xFFC9984B);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bgTop,
              Color(0xFF4E0A1B),
              bgBottom,
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
                  color: topGlow.withOpacity(0.78),
                  boxShadow: [
                    BoxShadow(
                      color: topGlow.withOpacity(0.45),
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
                  color: const Color(0xFFCC5E24).withOpacity(0.72),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCC5E24).withOpacity(0.35),
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
                  color: const Color(0xFFB10E2D).withOpacity(0.88),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB10E2D).withOpacity(0.35),
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
                          const SizedBox(height: 70),
                          Text(
                            "Maamah's Mix",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
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
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create account',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join Mix and enjoy seamless shopping, rides and deliveries.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.78),
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
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _GlassField(
                                  controller: _confirmPasswordCtrl,
                                  hint: 'Confirm password',
                                  icon: Icons.lock_person_outlined,
                                  obscureText: _obscureConfirmPassword,
                                  suffix: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _signup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonRed,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shadowColor: Colors.black.withOpacity(0.25),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
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
                                            'Create account',
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
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      child: Text(
                                        'or',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.78),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: OutlinedButton(
                                    onPressed: _googleLoading ? null : _signupWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.22),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Colors.white.withOpacity(0.03),
                                    ),
                                    child: _googleLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'G',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
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
                                        'Already have an account?',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.72),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: _goToLogin,
                                        child: Text(
                                          'Sign in',
                                          style: GoogleFonts.poppins(
                                            color: accentGold,
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
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 12.5,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.65),
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: Colors.white, size: 26),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}
