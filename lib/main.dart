import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mix/services/fcm_service.dart';
import 'package:mix/services/local_notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(FcmService.backgroundHandler);

  await LocalNotificationService.instance.initialize();
  await FcmService.instance.initialize();

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
