import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 👈 NEEDED
import 'package:get/get.dart'; 

import '../../presentation/customer/plans/widgets/plan_details_loader_screen.dart';

// ✅ 1. THE INTERFACE
// Both CustomerRepository and VendorRepository will implement this.
abstract class INotificationRepository {
  Future<void> updateFcmToken(String uid, String token);
}

// ✅ 2. THE SERVICE
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Depend on the Interface, not the concrete class
  final INotificationRepository repo; 

  NotificationService(this.repo);

  Future<void> initialize(String uid) async {
    // A. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notifications Authorized');

      // B. Create Channel (Android)
      await _createNotificationChannel(); 

      // C. Force iOS Foreground
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // D. Get & Save Token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        await repo.updateFcmToken(uid, token); // 👈 Uses the interface
      }

      // E. Listen for Refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        repo.updateFcmToken(uid, newToken);
      });

      // F. Setup Handlers
      _setupInteractedMessage();
    }
  }

  // --- 🛠️ CREATE CHANNEL ---
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'korra_high_importance_channel', // Must match Webhook
      'High Importance Notifications',
      description: 'Used for important account alerts.',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    // Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon'); 
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // --- 🚀 MESSAGE HANDLERS ---
  void _setupInteractedMessage() async {
    // 1. App Opened from Terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleNavigation(initialMessage);

    // 2. App Opened from Background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);
    
    // 3. App is FOREGROUND (Show Banner)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'korra_high_importance_channel',
              'High Importance Notifications',
              // ✅ 1. SMALL ICON (Status Bar) - Must be the White/Transparent one
              icon: '@drawable/notification_icon', 

              // ✅ 2. COLOR (Accent) - This paints the text and the small icon orange
              color: const Color(0xFFA54600), 

              // ✅ 3. LARGE ICON (Side Image) - Keeps your colored brand logo!
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),

              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data.toString(), 
        );
      }
    });
  }

  // --- 🧭 NAVIGATION ---
  void _handleNavigation(RemoteMessage message) {
    final type = message.data['type'];
    final id = message.data['planId'] ?? message.data['id']; 

    debugPrint("🚀 Navigating: Type=$type, ID=$id");

    if (id != null) {
      if (type == 'plan_detail') {
        // ✅ Customer: Go to Customer Loader
        Get.to(() => PlanDetailsLoaderScreen(planId: id));
      } 
    }
  }
}