import 'package:flutter/material.dart';
import 'package:mix/bootstrap.dart';
import 'package:mix/core/theme/app_theme.dart';
import 'package:mix/core/theme/theme_controller.dart';
import 'package:mix/core/theme/theme_scope.dart';

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
            title: 'Maamah\'s Mix',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeController.themeMode,
            home: const MixBootstrap(),
          );
        },
      ),
    );
  }
}
