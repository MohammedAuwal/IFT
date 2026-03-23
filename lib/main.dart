import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix/services/fcm_service.dart';
import 'package:mix/services/local_notification_service.dart';
import 'app.dart';

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

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  runApp(const MixApp());

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
