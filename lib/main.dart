import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix/services/fcm_service.dart';
import 'package:mix/services/local_notification_service.dart';
import 'app.dart';

Future<void> main() async {
  // 1. Bind Engine immediately
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Set System UI (Visual stability)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2A0A12),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF12060A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 3. Initialize Firebase
  // We keep this awaited as it's critical for the App to function (Providers, etc)
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Prevent hard crash
  }

  // 4. Run App IMMEDIATELY
  // We do NOT await FCM or Notifications here. They are slow and blocking.
  runApp(const MixApp());

  // 5. Initialize Services in Background
  // This ensures the UI is already drawing while these load
  _initBackgroundServices();
}

Future<void> _initBackgroundServices() async {
  try {
    FirebaseMessaging.onBackgroundMessage(FcmService.backgroundHandler);
  } catch (_) {}

  try {
    await LocalNotificationService.instance.initialize();
  } catch (_) {}

  try {
    await FcmService.instance.initialize();
  } catch (_) {}
}
