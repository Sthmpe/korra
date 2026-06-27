import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import BOTH files with aliases
import 'config/firebase_options_dev.dart' as dev;
import 'config/firebase_options_prod.dart' as prod;
import '../../logic/services/auth_service.dart';
import '../../logic/services/notification_service.dart';

Future<void> bootstrap({required bool isLive}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. System UI Setup
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.dark, 
    ),
  );
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Initialize Firebase with the correct Options
  await Firebase.initializeApp(
    options: isLive 
        ? prod.DefaultFirebaseOptions.currentPlatform 
        : dev.DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Load Environment Variables 
  // You can even have two .env files if you prefer: .env.prod and .env.dev
  await dotenv.load(fileName: isLive ? ".env.prod" : ".env");

  // 4. Supabase Setup
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase keys not found in environment file');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: !isLive, // Disable debug logs in Production
  );

  // 5. Auth Service
  await Get.putAsync(() => AuthService().init());

  // 6. Notification Service
  Get.put(NotificationService());
}