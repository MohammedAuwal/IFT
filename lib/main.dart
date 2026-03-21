import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix/services/fcm_service.dart';
import 'package:mix/services/local_notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Prevent hard crash at startup if Firebase init has an issue.
  }

  try {
    FirebaseMessaging.onBackgroundMessage(FcmService.backgroundHandler);
  } catch (_) {
    // Prevent startup crash from background handler registration issue.
  }

  try {
    await LocalNotificationService.instance.initialize();
  } catch (_) {
    // Keep app opening even if local notification init fails.
  }

  try {
    await FcmService.instance.initialize();
  } catch (_) {
    // Keep app opening even if FCM init fails.
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2A0A12),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF12060A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MixApp());
}
