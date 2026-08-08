import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../repositories/user_repository.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;

  NotificationService({
    FirebaseMessaging? messaging,
    UserRepository? userRepository,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _userRepository = userRepository ?? UserRepository();

  Future<void> initialize(String currentUid, {Function(String emergencyId)? onEmergencyTap}) async {
    // 1. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Get token
      final token = await _messaging.getToken();
      if (token != null) {
        await _userRepository.saveFcmToken(currentUid, token);
      }

      // 3. Token refresh listener
      _messaging.onTokenRefresh.listen((newToken) async {
        await _userRepository.saveFcmToken(currentUid, newToken);
      });
    }

    // 4. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground notification payload handled in app state
    });

    // 5. Background message tap listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final emergencyId = message.data['emergencyId'];
      if (emergencyId != null && onEmergencyTap != null) {
        onEmergencyTap(emergencyId.toString());
      }
    });

    // 6. Terminated state message tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final emergencyId = initialMessage.data['emergencyId'];
      if (emergencyId != null && onEmergencyTap != null) {
        onEmergencyTap(emergencyId.toString());
      }
    }
  }
}
