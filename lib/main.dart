//import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/constants/prefs_keys.dart';
import 'firebase_options.dart';
import 'korra_app.dart';
import 'logic/core/net/net_cubit.dart';
import 'logic/core/update/update_cubit.dart';
import 'presentation/auth/role_login/role_login_screen.dart';
import 'presentation/customer/customer_shell.dart';
import 'presentation/vendor/vendor_shell.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 🔹 Make status bar transparent
      statusBarIconBrightness: Brightness.dark, // or Brightness.light for white icons
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // // Initialize App Check
  // await FirebaseAppCheck.instance.activate(
  //   // specific for Android debug builds
  //   androidProvider: AndroidProvider.debug, 
    
  //   // specific for iOS/Web if needed
  //   appleProvider: AppleProvider.debug, 
  // );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception("Supabase Keys not found! Did you run with --dart-define?");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: false, // Turn off debug for release
  );

  // Determine the starting screen asynchronously before running the app.
  final startScreen = await _getStartScreen();

  runApp(
    MultiBlocProvider( 
      providers: [
        BlocProvider(create: (_) => NetCubit()..start()),
        BlocProvider(create: (_) => UpdateCubit()), 
      ],
      child: KorraApp(startScreen: startScreen),
    ),
  );
}

Future<Widget> _getStartScreen() async {
  final user = FirebaseAuth.instance.currentUser;
  // If no Firebase user is logged in, show the login screen.
  if (user == null) {
    return const RoleLoginScreen();
  }

  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString(PrefsKeys.userUid);
  final role = prefs.getString(PrefsKeys.userRole);


  // Check for a mismatch between the current Firebase user and the saved local data.
  if (uid == null || role == null || uid != user.uid) {
    return const RoleLoginScreen();
  }

  // A match is found, route to the correct role-based shell.
  if (role == 'vendor') {
    return VendorShell(uid: uid);
  } else {
    return CustomerShell(uid: uid);
  }
}