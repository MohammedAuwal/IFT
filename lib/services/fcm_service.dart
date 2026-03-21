import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mix/core/constants/app_constants.dart';
import 'package:mix/services/local_notification_service.dart';
import 'package:mix/services/notification_navigation_service.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> backgroundHandler(RemoteMessage message) async {
    // Background messages are handled by Firebase.
    // We intentionally keep this lightweight.
  }

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _saveCurrentToken();
    _listenTokenRefresh();
    _listenForegroundMessages();
    _listenNotificationTapEvents();
    await _handleInitialMessage();
  }

  Future<void> _saveCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;

    await _saveTokenForUser(user.uid, token);
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      final user = _auth.currentUser;
      if (user == null) return;
      await _saveTokenForUser(user.uid, token);
    });
  }

  Future<void> _saveTokenForUser(String uid, String token) async {
    final ref = _firestore.collection(AppConstants.usersCollection).doc(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final existing = List<String>.from(data['fcmTokens'] ?? []);

    if (!existing.contains(token)) {
      existing.add(token);
    }

    await ref.set({
      'fcmTokens': existing,
      'lastTokenUpdatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    final adminRef = _firestore.collection(AppConstants.adminsCollection).doc(uid);
    final adminSnap = await adminRef.get();
    if (adminSnap.exists) {
      final adminData = adminSnap.data() ?? {};
      final adminTokens = List<String>.from(adminData['fcmTokens'] ?? []);
      if (!adminTokens.contains(token)) {
        adminTokens.add(token);
      }

      await adminRef.set({
        'fcmTokens': adminTokens,
        'lastTokenUpdatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final title =
          message.notification?.title ?? (message.data['title'] ?? 'Mix');
      final body =
          message.notification?.body ?? (message.data['body'] ?? 'You have a new update');

      await LocalNotificationService.instance.show(
        title: title.toString(),
        body: body.toString(),
      );
    });
  }

  void _listenNotificationTapEvents() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await NotificationNavigationService.instance.handlePayload(message.data);
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;
    await NotificationNavigationService.instance
        .handlePayload(initialMessage.data);
  }
}
