import 'package:flutter/material.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/core/theme/app_theme.dart';
import 'package:mix/core/theme/theme_controller.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/splash/presentation/screens/splash_screen.dart';

class MixApp extends StatefulWidget {
  const MixApp({super.key});

  @override
  State<MixApp> createState() => _MixAppState();
}

class _MixAppState extends State<MixApp> {
  final ThemeController _themeController = ThemeController();

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: "Maamah's Mix",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeController.themeMode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
