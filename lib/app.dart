import 'package:flutter/material.dart';
import 'package:mix/bootstrap.dart';
import 'package:mix/core/theme/app_theme.dart';

class MixApp extends StatelessWidget {
  const MixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maamah\'s Mix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MixBootstrap(),
    );
  }
}
