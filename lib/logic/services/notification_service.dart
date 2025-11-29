import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final CustomerRepository repo;

  NotificationService(this.repo);

  Future<void> initialize(String customerUid) async {
    // 1. Request Permission (Critical for iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      
      // 2. ENGINEERING FIX: Force Foreground Presentation
      // This makes the notification pop up even if the app is open!
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, // Show Banner
        badge: true,
        sound: true, // Play Sound
      );

      // 3. Get & Save Token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        await repo.updateFcmToken(customerUid, token);
      }

      // 4. Token Refresh Listener
      _fcm.onTokenRefresh.listen((newToken) {
        repo.updateFcmToken(customerUid, newToken);
      });
    }
  }
}