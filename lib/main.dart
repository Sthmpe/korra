//import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/routes/app_routes.dart'; // ✅ Import Routes
import 'firebase_options.dart';
import 'korra_app.dart';
import 'logic/core/net/net_cubit.dart';
import 'logic/core/update/update_cubit.dart';
import 'logic/services/auth_service.dart';

// We removed screen imports because we only need Routes now

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.dark, 
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception("Supabase Keys not found! Did you run with --dart-define?");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: false, 
  );

  // 🚀 LOAD AUTH SERVICE FIRST
  // This loads SharedPreferences and User Role into memory
  await Get.putAsync(() => AuthService().init());

  // 🔄 DETERMINE ROUTE INSTANTLY
  // Now we can just ask the Service directly (No await needed!)
  final auth = AuthService.to;
  String initialRoute = Routes.roleLoginScreen;

  if (auth.isLoggedIn && auth.role != null) {
    if (auth.role == 'vendor') {
      initialRoute = Routes.vendorShell;
    } else {
      initialRoute = Routes.customerShell;
    }
  }

  runApp(
    MultiBlocProvider( 
      providers: [
        BlocProvider(create: (_) => NetCubit()..start()),
        BlocProvider(create: (_) => UpdateCubit()), 
      ],
      // 🔄 CHANGED: Passing String
      child: KorraApp(initialRoute: initialRoute), 
    ),
  );
}
