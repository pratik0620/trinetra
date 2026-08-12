import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/offline_emergency_model.dart';
import '../repositories/emergency_repository.dart';
import '../repositories/user_repository.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;
  final EmergencyRepository _emergencyRepository;
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
    EmergencyRepository? emergencyRepository,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _userRepository = userRepository ?? UserRepository(),
        _emergencyRepository = emergencyRepository ?? EmergencyRepository(),
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize(
    String currentUid, {
    required Function(String emergencyId) onEmergencyTap,
  }) async {
    try {
      // 1. Initialize Local Notifications Plugin for Android foreground alerts
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInitSettings);

      await _localNotifications
          .initialize(
            initSettings,
            onDidReceiveNotificationResponse: (response) {
              final payload = response.payload;
              if (payload != null && payload.isNotEmpty) {
                onEmergencyTap(payload);
              }
            },
          )
          .timeout(const Duration(seconds: 3), onTimeout: () => false);

      // Create high-importance Android channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_emergencyChannel)
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (e) {
      debugPrint('Local notifications init note: $e');
    }

    // 2. Request Notification Permission
    try {
      final settings = await _messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 4));

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 3. Get FCM Registration Token
        try {
          final token = await _messaging
              .getToken()
              .timeout(const Duration(seconds: 5), onTimeout: () => null);

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
    } catch (e) {
      debugPrint('FCM permission / token setup note: $e');
    }

    // 5. FOREGROUND MESSAGES — Parse payload & show high-priority alert
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
        final offlineModel = OfflineEmergencyModel.fromFcmPayload(data);
        _emergencyRepository.registerOfflineEmergency(offlineModel);

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
        final offlineModel = OfflineEmergencyModel.fromFcmPayload(data);
        _emergencyRepository.registerOfflineEmergency(offlineModel);
        onEmergencyTap(emergencyId.toString());
      }
    });

    // 7. TERMINATED STATE — Handle notification tap when app was terminated
    try {
      final initialMessage = await _messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

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
          final offlineModel = OfflineEmergencyModel.fromFcmPayload(data);
          _emergencyRepository.registerOfflineEmergency(offlineModel);
          onEmergencyTap(emergencyId.toString());
        }
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage note: $e');
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

  void showNotification({required String title, required String body, required String payload}) {
    _showForegroundNotification(title: title, body: body, payload: payload);
  }

  Future<void> clearFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _userRepository.removeFcmToken(uid, token);
        debugPrint('FCM TOKEN REMOVED ON LOGOUT');
      }
    } catch (e) {
      debugPrint('FCM token removal note: $e');
    }
  }
}
