import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../config/routes/app_routes.dart';

import 'dart:async';

// ✅ 1. THE INTERFACE
abstract class INotificationRepository {
  Future<void> updateFcmToken(String uid, String token);
}

// ✅ 2. THE SERVICE
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _listenersRegistered = false;
  INotificationRepository? _currentRepo;
  String? _currentUid;
  StreamSubscription<String>? _tokenRefreshSubscription;

  NotificationService();

  Future<void> initialize(INotificationRepository repo, String uid) async {
    // 1. Setup channel and message handlers once
    if (!_listenersRegistered) {
      _listenersRegistered = true;
      
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

        // F. Setup Handlers
        _setupInteractedMessage();
      }
    }

    // 2. Token generation and refresh listener per user session
    NotificationSettings settings = await _fcm.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        await repo.updateFcmToken(uid, token); 
      }

      _currentRepo = repo;
      _currentUid = uid;

      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
        if (_currentRepo != null && _currentUid != null) {
          _currentRepo!.updateFcmToken(_currentUid!, newToken);
        }
      });
    }
  }

  // --- 🛠️ CREATE CHANNEL ---
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'korra_high_importance_channel', 
      'High Importance Notifications',
      description: 'Used for important account alerts.',
      importance: Importance.max, // Changed to Max for images
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon'); 
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // --- 📸 HELPER: DOWNLOAD IMAGE ---
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  // --- 🚀 MESSAGE HANDLERS ---
  void _setupInteractedMessage() async {
    // 1. App Opened from Terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleNavigation(initialMessage);

    // 2. App Opened from Background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);
    
    // 3. App is FOREGROUND (Show Banner)
    // ⚠️ Note: Changed to async so we can await the image download
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async { 
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        
        // 🖼️ Extract image from the data payload we sent from backend
        String? imageUrl = message.data['image'];
        BigPictureStyleInformation? bigPictureStyle;

        // If an image URL exists, download it and create the BigPictureStyle
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final String largeIconPath = await _downloadAndSaveFile(imageUrl, 'notification_image_${notification.hashCode}.jpg');
            bigPictureStyle = BigPictureStyleInformation(
              FilePathAndroidBitmap(largeIconPath),
              hideExpandedLargeIcon: false,
            );
          } catch (e) {
            debugPrint("⚠️ Failed to download notification image: $e");
          }
        }

        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'korra_high_importance_channel',
              'High Importance Notifications',
              icon: '@drawable/notification_icon', 
              color: const Color(0xFFA54600), 
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
              
              // ✅ Apply the image style if it exists
              styleInformation: bigPictureStyle, 

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
        Get.toNamed(
          Routes.customerPlanDetailsLoader,
          arguments: {'planId': id},
        );
        return;
      }
      // Add vendor routing here later if needed!
      // else if (type == 'vendor_order') { ... }
    }

    // Last Viewed re-engagement push: straight to the product inside its
    // merchant's storefront (slug preferred, vendorId resolves too).
    if (type == 'last_viewed') {
      final productId = (message.data['productId'] ?? '').toString();
      final slug = (message.data['slug'] ?? '').toString().trim().isNotEmpty
          ? message.data['slug'].toString().trim()
          : (message.data['vendorId'] ?? '').toString();
      if (slug.isNotEmpty && productId.isNotEmpty) {
        Get.toNamed('/store/$slug', parameters: {'product': productId});
      }
    }
  }
}