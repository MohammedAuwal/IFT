import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = FirebaseAuthService();

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      _toast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signInEmail() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    await _run(() async {
      await _authService.signInWithEmailPassword(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    });
  }

  Future<void> _signUpEmail() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    await _run(() async {
      await _authService.signUpWithEmailPassword(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    });
  }

  Future<void> _signInGoogle() async {
    await _run(() async {
      await _authService.signInWithGoogle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // Premium warm background (deep red + warm gold)
          const _WarmGradientBackground(),

          // Decorative blurred "spice lights"
          Positioned(
            top: -80,
            left: -40,
            child: _GlowBlob(
              diameter: size.width * 0.72,
              color: const Color(0xFFFFD166).withOpacity(0.55),
            ),
          ),
          Positioned(
            bottom: -110,
            right: -70,
            child: _GlowBlob(
              diameter: size.width * 0.85,
              color: const Color(0xFFB80F2B).withOpacity(0.55),
            ),
          ),
          Positioned(
            top: size.height * 0.22,
            right: -50,
            child: _GlowBlob(
              diameter: size.width * 0.55,
              color: const Color(0xFFFF7A18).withOpacity(0.42),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _BrandHeader(
                        title: "Maamah's Mix",
                        subtitle: "Premium African spices, flours & traditional foods",
                      ),
                      const SizedBox(height: 18),

                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Welcome back",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Sign in to continue your premium shopping experience.",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),

                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _PremiumTextField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    hintText: "Email address",
                                    prefixIcon: Icons.mail_rounded,
                                    validator: (v) {
                                      final s = (v ?? '').trim();
                                      if (s.isEmpty) return 'Email is required';
                                      if (!s.contains('@') || !s.contains('.')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _PremiumTextField(
                                    controller: _passwordCtrl,
                                    keyboardType: TextInputType.visiblePassword,
                                    hintText: "Password",
                                    prefixIcon: Icons.lock_rounded,
                                    obscureText: _obscure,
                                    validator: (v) {
                                      final s = (v ?? '');
                                      if (s.isEmpty) return 'Password is required';
                                      if (s.length < 6) return 'Minimum 6 characters';
                                      return null;
                                    },
                                    suffix: IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            _PrimaryButton(
                              loading: _loading,
                              text: "Sign in",
                              onTap: _signInEmail,
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.18), height: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    "or",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.18), height: 1)),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _GoogleButton(
                              loading: _loading,
                              onTap: _signInGoogle,
                            ),

                            const SizedBox(height: 14),

                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "New here? ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loading ? null : _signUpEmail,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFFFD166),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  child: Text(
                                    "Create an account",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "By continuing, you agree to our Terms & Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
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

class _WarmGradientBackground extends StatelessWidget {
  const _WarmGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A0A12), // deep wine
            Color(0xFF4B0D1F), // spicy burgundy
            Color(0xFF12060A), // near-black warm
          ],
          stops: [0.0, 0.55, 1.0],
        ),
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
      imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.8,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.78),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18), width: 1),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: const Color(0xFFFFD166),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.65),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.9)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFFFD166), width: 1.2),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.9), width: 1.1),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.9), width: 1.1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorStyle: GoogleFonts.poppins(
          color: Colors.redAccent.withOpacity(0.95),
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onTap,
    required this.loading,
  });

  final String text;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD166), // warm gold
              Color(0xFFFF7A18), // orange spice
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A18).withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                )
              : Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.onTap,
    required this.loading,
  });

  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
          backgroundColor: Colors.white.withOpacity(0.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.92),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sign in with Google',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
