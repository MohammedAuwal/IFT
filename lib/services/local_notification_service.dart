import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mix/services/notification_navigation_service.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'mix_high_importance_channel',
    'Mix Notifications',
    description: 'Important alerts for rides, deliveries, orders, and admin ops',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher_placeholder');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            await NotificationNavigationService.instance.handlePayload(decoded);
            return;
          }

          if (decoded is Map) {
            await NotificationNavigationService.instance.handlePayload(
              decoded.map(
                (key, value) =>
                    MapEntry(key.toString(), value?.toString() ?? ''),
              ),
            );
          }
        } catch (_) {}
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    final launchPayload = launchResponse?.payload;

    if (launchPayload != null && launchPayload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(launchPayload);
        if (decoded is Map<String, dynamic>) {
          Future.microtask(() async {
            await NotificationNavigationService.instance.handlePayload(decoded);
          });
        } else if (decoded is Map) {
          Future.microtask(() async {
            await NotificationNavigationService.instance.handlePayload(
              decoded.map(
                (key, value) =>
                    MapEntry(key.toString(), value?.toString() ?? ''),
              ),
            );
          });
        }
      } catch (_) {}
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_launcher_placeholder',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
