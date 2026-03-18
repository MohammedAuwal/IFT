import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../services/firebase_auth_service.dart';
import '../../../../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = FirebaseAuthService();
  final _firebaseService = FirebaseService();

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuthSuccess(User? user) async {
    if (user == null || !mounted) return;

    try {
      await _firebaseService.ensureUserProfile();
      await _firebaseService.syncLocalCartToFirestore();
    } catch (_) {
      // Non-critical — continue even if sync fails
    }

    if (!mounted) return;

    try {
      final isAdmin = await _firebaseService.isAdmin();
      if (!mounted) return;

      if (isAdmin) {
        await AppRouter.clearAndGo(context, RouteNames.admin);
      } else {
        await AppRouter.clearAndGo(context, RouteNames.mainShell);
      }
    } catch (_) {
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    }

    if (!mounted) return;

    final displayName = user.displayName ?? user.email ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSignUp
              ? "Account created! Welcome $displayName 🎉"
              : "Welcome back 👋 $displayName",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _run(Future<User?> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final user = await action();
      if (user == null) {
        // User cancelled (e.g. Google sign-in cancelled)
        return;
      }
      await _handleAuthSuccess(user);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('firebase_auth')) {
        _toast('Authentication failed. Please try again.');
      } else {
        _toast(msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
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
      return await _authService.signInWithEmailPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    });
  }

  Future<void> _signUpEmail() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final fullName = _nameCtrl.text.trim();

    await _run(() async {
      final user = await _authService.signUpWithEmailPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Set display name on Firebase Auth profile
      if (user != null && fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }

      return _authService.currentUser;
    });
  }

  Future<void> _signInGoogle() async {
    await _run(() async {
      return await _authService.signInWithGoogle();
    });
  }

  void _toggleMode() {
    if (_loading) return;
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          const _WarmGradientBackground(),
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
                        subtitle:
                            "Premium African spices, flours & traditional foods",
                      ),
                      const SizedBox(height: 18),
                      _GlassCard(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isSignUp ? "Create account" : "Welcome back",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isSignUp
                                    ? "Join us for a premium shopping experience."
                                    : "Sign in to continue your premium shopping experience.",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Full name field — only shown in sign up mode
                                    if (_isSignUp) ...[
                                      _PremiumTextField(
                                        controller: _nameCtrl,
                                        keyboardType: TextInputType.name,
                                        hintText: "Full name",
                                        prefixIcon: Icons.person_rounded,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        validator: (v) {
                                          final s = (v ?? '').trim();
                                          if (s.isEmpty) {
                                            return 'Full name is required';
                                          }
                                          if (s.length < 2) {
                                            return 'Name is too short';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    _PremiumTextField(
                                      controller: _emailCtrl,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      hintText: "Email address",
                                      prefixIcon: Icons.mail_rounded,
                                      validator: (v) {
                                        final s = (v ?? '').trim();
                                        if (s.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!s.contains('@') ||
                                            !s.contains('.')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _PremiumTextField(
                                      controller: _passwordCtrl,
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      hintText: "Password",
                                      prefixIcon: Icons.lock_rounded,
                                      obscureText: _obscure,
                                      validator: (v) {
                                        final s = (v ?? '');
                                        if (s.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (s.length < 6) {
                                          return 'Minimum 6 characters';
                                        }
                                        return null;
                                      },
                                      suffix: IconButton(
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color:
                                              Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PrimaryButton(
                                loading: _loading,
                                text: _isSignUp ? "Create account" : "Sign in",
                                onTap:
                                    _isSignUp ? _signUpEmail : _signInEmail,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.18),
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      "or",
                                      style: GoogleFonts.poppins(
                                        color:
                                            Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.18),
                                      height: 1,
                                    ),
                                  ),
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
                                children: [
                                  Text(
                                    _isSignUp
                                        ? "Already have an account? "
                                        : "New here? ",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color:
                                          Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _loading ? null : _toggleMode,
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFFFFD166),
                                    ),
                                    child: Text(
                                      _isSignUp
                                          ? "Sign in"
                                          : "Create an account",
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
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "By continuing, you agree to our Terms & Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11.5,
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
            Color(0xFF2A0A12),
            Color(0xFF4B0D1F),
            Color(0xFF12060A),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.diameter, required this.color});

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
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.8,
            color: Colors.white.withOpacity(0.78),
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
            border: Border.all(color: Colors.white.withOpacity(0.20)),
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
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(0.18),
        width: 1,
      ),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textCapitalization: textCapitalization,
      style: GoogleFonts.poppins(color: Colors.white),
      cursorColor: const Color(0xFFFFD166),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.65),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.white.withOpacity(0.9),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(
            color: Color(0xFFFFD166),
            width: 1.2,
          ),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: BorderSide(
            color: Colors.red.withOpacity(0.6),
            width: 1,
          ),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: BorderSide(
            color: Colors.red.withOpacity(0.8),
            width: 1.2,
          ),
        ),
        errorStyle: GoogleFonts.poppins(
          color: const Color(0xFFFF6B6B),
          fontSize: 11,
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
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9E2323),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9E2323).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
          side: BorderSide(color: Colors.white.withOpacity(0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
