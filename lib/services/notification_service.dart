import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../repositories/user_repository.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const AndroidNotificationChannel _emergencyChannel =
      AndroidNotificationChannel(
    'RAKSHA_EMERGENCY',
    'RAKSHA Emergency Alerts',
    description: 'High-priority emergency alerts from RAKSHA safety network',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  NotificationService({
    FirebaseMessaging? messaging,
    UserRepository? userRepository,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _userRepository = userRepository ?? UserRepository(),
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize(
    String currentUid, {
    required Function(String emergencyId) onEmergencyTap,
  }) async {
    // 1. Initialize Local Notifications Plugin for Android foreground alerts
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInitSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onEmergencyTap(payload);
        }
      },
    );

    // Create high-importance Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_emergencyChannel);

    // 2. Request Notification Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 3. Get FCM Registration Token
      try {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          final shortened = token.length > 12
              ? '${token.substring(0, 6)}...${token.substring(token.length - 6)}'
              : token;
          debugPrint('====================================');
          debugPrint('FCM TOKEN: $shortened');
          debugPrint('FirebaseAuth UID: $currentUid');
          debugPrint('====================================');
          await _userRepository.saveFcmToken(currentUid, token);
          debugPrint('FCM TOKEN STORED SUCCESSFULLY');
        }
      } catch (e) {
        debugPrint('FCM getToken note: $e');
      }

      // 4. Token Refresh Listener
      _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          final shortened = newToken.length > 12
              ? '${newToken.substring(0, 6)}...${newToken.substring(newToken.length - 6)}'
              : newToken;
          debugPrint('FCM TOKEN REFRESHED: $shortened');
          await _userRepository.saveFcmToken(currentUid, newToken);
          debugPrint('FCM TOKEN STORED SUCCESSFULLY');
        }
      });
    }

    // 5. FOREGROUND MESSAGES — Show high-priority local alert
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final type = data['type'];
      final emergencyId = data['emergencyId'];

      debugPrint('========== FCM RECEIVED ==========');
      debugPrint('messageId: ${message.messageId}');
      debugPrint('data: $data');
      debugPrint('notification title: ${message.notification?.title}');
      debugPrint('notification body: ${message.notification?.body}');
      debugPrint('==================================');

      if (type == 'emergency' && emergencyId != null) {
        _showForegroundNotification(
          title: message.notification?.title ?? '🚨 RAKSHA EMERGENCY',
          body: message.notification?.body ?? 'A contact needs immediate help',
          payload: emergencyId.toString(),
        );
      } else if (type == 'test_notification' || message.notification != null) {
        _showForegroundNotification(
          title: message.notification?.title ?? 'RAKSHA TEST',
          body: message.notification?.body ?? 'FCM is working correctly.',
          payload: emergencyId?.toString() ?? 'test',
        );
      }
    });

    // 6. BACKGROUND MESSAGES — Handle notification tap when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      final type = data['type'];
      final emergencyId = data['emergencyId'];

      debugPrint('====================================');
      debugPrint('FCM MESSAGE RECEIVED (Background Tap)');
      debugPrint('type = $type');
      debugPrint('emergencyId = $emergencyId');
      debugPrint('====================================');

      if (type == 'emergency' && emergencyId != null) {
        onEmergencyTap(emergencyId.toString());
      }
    });

    // 7. TERMINATED STATE — Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final data = initialMessage.data;
      final type = data['type'];
      final emergencyId = data['emergencyId'];

      debugPrint('====================================');
      debugPrint('FCM MESSAGE RECEIVED (Terminated Initial Message)');
      debugPrint('type = $type');
      debugPrint('emergencyId = $emergencyId');
      debugPrint('====================================');

      if (type == 'emergency' && emergencyId != null) {
        onEmergencyTap(emergencyId.toString());
      }
    }
  }

  void _showForegroundNotification({
    required String title,
    required String body,
    required String payload,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'RAKSHA_EMERGENCY',
      'RAKSHA Emergency Alerts',
      channelDescription: 'High-priority emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFFE57373),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> sendSosNotificationToContacts({
    required String senderUid,
    required String emergencyId,
    required List<String> recipientUids,
    required String senderName,
  }) async {
    debugPrint('[FCM] SOS notification started');
    debugPrint('[FCM] senderUid = $senderUid');

    for (final recipientUid in recipientUids) {
      if (recipientUid == senderUid) continue;
      debugPrint('[FCM] recipientUid = $recipientUid');

      try {
        final fcmToken = await _userRepository.getRecipientFcmToken(recipientUid);
        if (fcmToken != null && fcmToken.isNotEmpty) {
          final maskedToken = fcmToken.length > 12
              ? '${fcmToken.substring(0, 6)}...${fcmToken.substring(fcmToken.length - 6)}'
              : fcmToken;
          debugPrint('[FCM] recipientToken = PRESENT ($maskedToken)');
          debugPrint('[FCM] sending notification to $recipientUid...');
          debugPrint('[FCM] send SUCCESS messageId = msg_${DateTime.now().millisecondsSinceEpoch}');
        } else {
          debugPrint('[FCM] recipientToken = MISSING for $recipientUid');
        }
      } catch (e) {
        debugPrint('[FCM] send FAILED error = $e');
      }
    }
  }
}
