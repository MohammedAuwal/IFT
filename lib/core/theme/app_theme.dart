import 'dart:ui';
import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  static const Color primary = Color(0xFFC29B40);
  static const Color primaryDark = Color(0xFFAA8330);
  static const Color secondary = Color(0xFF7C1820);
  static const Color success = Color(0xFF2EAD62);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Light
  static const Color lightScaffold = Color(0xFFF8F5EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF8F5EF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE9DFC6);
  static const Color lightBorderSoft = Color(0xFFE8DDC0);
  static const Color lightText = Color(0xFF1D1D1F);
  static const Color lightTextSoft = Color(0xFF6B6B70);
  static const Color lightIcon = Color(0xFF1D1D1F);
  static const Color lightShadow = Color(0x14000000);

  // Dark
  static const Color darkScaffold = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkSurfaceAlt = Color(0xFF11141A);
  static const Color darkCard = Color(0xFF171A21);
  static const Color darkBorder = Color(0x26FFFFFF);
  static const Color darkBorderSoft = Color(0x1AFFFFFF);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSoft = Color(0xB3FFFFFF);
  static const Color darkIcon = Color(0xFFF5F5F5);
  static const Color darkShadow = Color(0x33000000);

  // Shared chips / accents
  static const Color orange = Color(0xFFFF7A00);
  static const Color cream = Color(0xFFF1E4BE);
  static const Color brown = Color(0xFF7A5A12);
  static const Color darkBrown = Color(0xFF3D2A00);
  static const Color purple = Color(0xFF5D34A4);
  static const Color palePurple = Color(0xFFF4EEFF);
  static const Color paleBlue = Color(0xFFEAF2FF);
  static const Color paleGreen = Color(0xFFEAFBF1);
  static const Color paleOrange = Color(0xFFFFF4E8);
  static const Color paleRed = Color(0xFFFFEFEF);
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color brandPrimary;
  final Color brandSecondary;
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconPrimary;
  final Color border;
  final Color borderSoft;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color cream;
  final Color brown;
  final Color darkBrown;
  final Color palePurple;
  final Color paleBlue;
  final Color paleGreen;
  final Color paleOrange;
  final Color paleRed;

  const AppThemeColors({
    required this.brandPrimary,
    required this.brandSecondary,
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconPrimary,
    required this.border,
    required this.borderSoft,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.cream,
    required this.brown,
    required this.darkBrown,
    required this.palePurple,
    required this.paleBlue,
    required this.paleGreen,
    required this.paleOrange,
    required this.paleRed,
  });

  factory AppThemeColors.light() {
    return const AppThemeColors(
      brandPrimary: AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      scaffold: AppPalette.lightScaffold,
      surface: AppPalette.lightSurface,
      surfaceAlt: AppPalette.lightSurfaceAlt,
      card: AppPalette.lightCard,
      textPrimary: AppPalette.lightText,
      textSecondary: AppPalette.lightTextSoft,
      iconPrimary: AppPalette.lightIcon,
      border: AppPalette.lightBorder,
      borderSoft: AppPalette.lightBorderSoft,
      shadow: AppPalette.lightShadow,
      success: AppPalette.success,
      warning: AppPalette.warning,
      error: AppPalette.error,
      info: AppPalette.info,
      cream: AppPalette.cream,
      brown: AppPalette.brown,
      darkBrown: AppPalette.darkBrown,
      palePurple: AppPalette.palePurple,
      paleBlue: AppPalette.paleBlue,
      paleGreen: AppPalette.paleGreen,
      paleOrange: AppPalette.paleOrange,
      paleRed: AppPalette.paleRed,
    );
  }

  factory AppThemeColors.dark() {
    return const AppThemeColors(
      brandPrimary: AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      scaffold: AppPalette.darkScaffold,
      surface: AppPalette.darkSurface,
      surfaceAlt: AppPalette.darkSurfaceAlt,
      card: AppPalette.darkCard,
      textPrimary: AppPalette.darkText,
      textSecondary: AppPalette.darkTextSoft,
      iconPrimary: AppPalette.darkIcon,
      border: AppPalette.darkBorder,
      borderSoft: AppPalette.darkBorderSoft,
      shadow: AppPalette.darkShadow,
      success: AppPalette.success,
      warning: AppPalette.warning,
      error: AppPalette.error,
      info: AppPalette.info,
      cream: AppPalette.cream,
      brown: AppPalette.brown,
      darkBrown: AppPalette.darkBrown,
      palePurple: AppPalette.palePurple,
      paleBlue: AppPalette.paleBlue,
      paleGreen: AppPalette.paleGreen,
      paleOrange: AppPalette.paleOrange,
      paleRed: AppPalette.paleRed,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? brandPrimary,
    Color? brandSecondary,
    Color? scaffold,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? iconPrimary,
    Color? border,
    Color? borderSoft,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? cream,
    Color? brown,
    Color? darkBrown,
    Color? palePurple,
    Color? paleBlue,
    Color? paleGreen,
    Color? paleOrange,
    Color? paleRed,
  }) {
    return AppThemeColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      cream: cream ?? this.cream,
      brown: brown ?? this.brown,
      darkBrown: darkBrown ?? this.darkBrown,
      palePurple: palePurple ?? this.palePurple,
      paleBlue: paleBlue ?? this.paleBlue,
      paleGreen: paleGreen ?? this.paleGreen,
      paleOrange: paleOrange ?? this.paleOrange,
      paleRed: paleRed ?? this.paleRed,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;

    Color l(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppThemeColors(
      brandPrimary: l(brandPrimary, other.brandPrimary),
      brandSecondary: l(brandSecondary, other.brandSecondary),
      scaffold: l(scaffold, other.scaffold),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      card: l(card, other.card),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      iconPrimary: l(iconPrimary, other.iconPrimary),
      border: l(border, other.border),
      borderSoft: l(borderSoft, other.borderSoft),
      shadow: l(shadow, other.shadow),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      info: l(info, other.info),
      cream: l(cream, other.cream),
      brown: l(brown, other.brown),
      darkBrown: l(darkBrown, other.darkBrown),
      palePurple: l(palePurple, other.palePurple),
      paleBlue: l(paleBlue, other.paleBlue),
      paleGreen: l(paleGreen, other.paleGreen),
      paleOrange: l(paleOrange, other.paleOrange),
      paleRed: l(paleRed, other.paleRed),
    );
  }
}

class AppTheme {
  static AppThemeColors colorsOf(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeColors>();
    assert(ext != null, 'AppThemeColors extension not found in ThemeData');
    return ext!;
  }

  static ThemeData light() {
    const colors = AppThemeColors(
      brandPrimary: AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      scaffold: AppPalette.lightScaffold,
      surface: AppPalette.lightSurface,
      surfaceAlt: AppPalette.lightSurfaceAlt,
      card: AppPalette.lightCard,
      textPrimary: AppPalette.lightText,
      textSecondary: AppPalette.lightTextSoft,
      iconPrimary: AppPalette.lightIcon,
      border: AppPalette.lightBorder,
      borderSoft: AppPalette.lightBorderSoft,
      shadow: AppPalette.lightShadow,
      success: AppPalette.success,
      warning: AppPalette.warning,
      error: AppPalette.error,
      info: AppPalette.info,
      cream: AppPalette.cream,
      brown: AppPalette.brown,
      darkBrown: AppPalette.darkBrown,
      palePurple: AppPalette.palePurple,
      paleBlue: AppPalette.paleBlue,
      paleGreen: AppPalette.paleGreen,
      paleOrange: AppPalette.paleOrange,
      paleRed: AppPalette.paleRed,
    );

    final colorScheme = ColorScheme.light(
      primary: colors.brandPrimary,
      secondary: colors.brandSecondary,
      surface: colors.surface,
      background: colors.scaffold,
      error: colors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: colors.textPrimary,
      onBackground: colors.textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: colors.brandPrimary,
      scaffoldBackgroundColor: colors.scaffold,
      canvasColor: colors.surface,
      dividerColor: colors.border,
      shadowColor: colors.shadow,
      splashColor: colors.brandPrimary.withOpacity(0.08),
      highlightColor: colors.brandPrimary.withOpacity(0.04),
      extensions: const [colors],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppPalette.lightText,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppPalette.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppPalette.lightText),
        bodyMedium: TextStyle(color: AppPalette.lightText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.scaffold,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.iconPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: IconThemeData(color: colors.iconPrimary),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderSoft),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.brandPrimary,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.brandPrimary,
        disabledColor: colors.borderSoft,
        side: BorderSide(color: colors.border),
        labelStyle: TextStyle(color: colors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary;
          }
          return colors.textSecondary.withOpacity(0.7);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary.withOpacity(0.35);
          }
          return colors.border;
        }),
      ),
    );
  }

  static ThemeData dark() {
    const colors = AppThemeColors(
      brandPrimary: AppPalette.primary,
      brandSecondary: AppPalette.secondary,
      scaffold: AppPalette.darkScaffold,
      surface: AppPalette.darkSurface,
      surfaceAlt: AppPalette.darkSurfaceAlt,
      card: AppPalette.darkCard,
      textPrimary: AppPalette.darkText,
      textSecondary: AppPalette.darkTextSoft,
      iconPrimary: AppPalette.darkIcon,
      border: AppPalette.darkBorder,
      borderSoft: AppPalette.darkBorderSoft,
      shadow: AppPalette.darkShadow,
      success: AppPalette.success,
      warning: AppPalette.warning,
      error: AppPalette.error,
      info: AppPalette.info,
      cream: AppPalette.cream,
      brown: AppPalette.brown,
      darkBrown: AppPalette.darkBrown,
      palePurple: AppPalette.palePurple,
      paleBlue: AppPalette.paleBlue,
      paleGreen: AppPalette.paleGreen,
      paleOrange: AppPalette.paleOrange,
      paleRed: AppPalette.paleRed,
    );

    final colorScheme = ColorScheme.dark(
      primary: colors.brandPrimary,
      secondary: colors.brandSecondary,
      surface: colors.surface,
      background: colors.scaffold,
      error: colors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: colors.textPrimary,
      onBackground: colors.textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: colors.brandPrimary,
      scaffoldBackgroundColor: colors.scaffold,
      canvasColor: colors.surface,
      dividerColor: colors.border,
      shadowColor: colors.shadow,
      splashColor: colors.brandPrimary.withOpacity(0.10),
      highlightColor: colors.brandPrimary.withOpacity(0.05),
      extensions: const [colors],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppPalette.darkText,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppPalette.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppPalette.darkText),
        bodyMedium: TextStyle(color: AppPalette.darkText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.scaffold,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.iconPrimary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: IconThemeData(color: colors.iconPrimary),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderSoft),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        hintStyle: TextStyle(color: colors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.brandPrimary,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.brandPrimary,
        disabledColor: colors.borderSoft,
        side: BorderSide(color: colors.border),
        labelStyle: TextStyle(color: colors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceAlt,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary;
          }
          return colors.textSecondary.withOpacity(0.7);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.brandPrimary.withOpacity(0.35);
          }
          return colors.border;
        }),
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
    final colors = AppTheme.colorsOf(context);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: colors.card.withOpacity(opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: colors.borderSoft,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
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
