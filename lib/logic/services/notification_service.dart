import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Import the interface definition (or define it in this file)
abstract class INotificationRepository {
  Future<void> updateFcmToken(String uid, String token);
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // 👇 Accept the Interface, not a specific class
  final INotificationRepository repo;

  NotificationService(this.repo);

  Future<void> initialize(String uid) async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      
      // 2. Force Foreground Presentation
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Get & Save Token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        // This works for ANY repo that implements the interface
        await repo.updateFcmToken(uid, token);
      }

      // 4. Token Refresh Listener
      _fcm.onTokenRefresh.listen((newToken) {
        repo.updateFcmToken(uid, newToken);
      });
    }
  }
}