import 'package:flutter/material.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/core/theme/app_theme.dart';
import 'package:mix/core/theme/theme_controller.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/splash/presentation/screens/splash_screen.dart';
import 'package:mix/services/admin_preview_controller.dart';

class MixApp extends StatefulWidget {
  const MixApp({super.key});

  @override
  State<MixApp> createState() => _MixAppState();
}

class _MixAppState extends State<MixApp> {
  final ThemeController _themeController = ThemeController();
  final AdminPreviewController _adminPreviewController =
      AdminPreviewController();

  @override
  void dispose() {
    _themeController.dispose();
    _adminPreviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _themeController,
          _adminPreviewController,
        ]),
        builder: (context, _) {
          return _AdminPreviewScope(
            controller: _adminPreviewController,
            child: MaterialApp(
              title: "Maamah's Mix",
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _themeController.themeMode,
              onGenerateRoute: AppRouter.onGenerateRoute,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _AdminPreviewScope extends InheritedNotifier<AdminPreviewController> {
  const _AdminPreviewScope({
    required AdminPreviewController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AdminPreviewController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_AdminPreviewScope>();
    assert(scope != null, 'No _AdminPreviewScope found in context');
    return scope!.notifier!;
  }
}
