import 'dart:ui';
import 'package:flutter/material.dart';

class AppPalette {
  static const Color primaryGold = Color(0xFFC29B40);
  static const Color accentCrimson = Color(0xFF8E2121);
  static const Color accentGreen = Color(0xFF4CAF50);

  static const Color lightScaffold = Color(0xFFFBFBFD);
  static const Color lightText = Color(0xFF1D1D1F);

  static const Color darkScaffold = Color(0xFF121212);
  static const Color darkText = Color(0xFFF5F5F5);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppPalette.primaryGold,
      scaffoldBackgroundColor: AppPalette.lightScaffold,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppPalette.lightText,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppPalette.primaryGold,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(color: AppPalette.lightText),
        bodyMedium: TextStyle(color: AppPalette.lightText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accentCrimson,
          foregroundColor: AppPalette.darkText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: AppPalette.lightText.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFDCDCE1),
            width: 1.0,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppPalette.primaryGold,
      scaffoldBackgroundColor: AppPalette.darkScaffold,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppPalette.darkText,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppPalette.primaryGold,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(color: AppPalette.darkText),
        bodyMedium: TextStyle(color: AppPalette.darkText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accentCrimson,
          foregroundColor: AppPalette.darkText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        hintStyle: TextStyle(color: AppPalette.darkText.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.white12,
            width: 1.0,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10, width: 1.0),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.6,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: (cardTheme.color ?? Colors.white).withOpacity(opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.white70,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
