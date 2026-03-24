import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix/app.dart';
import 'package:mix/services/fcm_service.dart';
import 'package:mix/services/local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  await FcmService.instance.handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF2A0A12),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF12060A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await LocalNotificationService.instance.initialize();
  await FcmService.instance.initialize();

  runApp(const MixApp());
}
