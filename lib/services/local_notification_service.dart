import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mix/services/notification_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _soundPrefKey = 'mix_notification_sound';

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'mix_high_importance_channel',
    'Mix Notifications',
    description: 'Important alerts for rides, deliveries, orders, and admin ops',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _silentChannel =
      AndroidNotificationChannel(
    'mix_silent_channel',
    'Mix Silent Notifications',
    description: 'Silent notifications without sound',
    importance: Importance.max,
    playSound: false,
    enableVibration: false,
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
        ?.createNotificationChannel(_defaultChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_silentChannel);

    _initialized = true;
  }

  /// Get current sound preference.
  /// Returns 'default', 'silent', or a custom name.
  Future<String> getNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_soundPrefKey) ?? 'default';
  }

  /// Set notification sound preference.
  Future<void> setNotificationSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundPrefKey, sound);
  }

  /// Get available sound options.
  List<String> get availableSounds => const [
        'default',
        'silent',
      ];

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    final soundPref = await getNotificationSound();

    final bool isSilent = soundPref == 'silent';

    final channelId =
        isSilent ? _silentChannel.id : _defaultChannel.id;
    final channelName =
        isSilent ? _silentChannel.name : _defaultChannel.name;
    final channelDesc =
        isSilent ? _silentChannel.description : _defaultChannel.description;

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_launcher_placeholder',
          playSound: !isSilent,
          enableVibration: !isSilent,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: !isSilent,
        ),
      ),
      payload: payload,
    );
  }
}
