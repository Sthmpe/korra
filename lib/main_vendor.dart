import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bootstrap.dart';
import 'config/routes/vendor_pages.dart';
import 'config/routes/app_routes.dart';
import 'flavors/app_config.dart';
import 'korra_app.dart'; // ✅ Uses your existing KorraApp
import 'logic/core/net/net_cubit.dart';
import 'logic/core/update/update_cubit.dart';
import 'logic/services/analytics_service.dart';
import 'logic/services/auth_service.dart';

void main() async {
  // 🚀 Capture the flag from the terminal command
  const bool isLive = bool.fromEnvironment('IS_LIVE', defaultValue: false);

  // 1. Run Shared Setup
  await bootstrap(isLive: isLive);

  // 2. Set Identity: VENDOR (MERCHANT)
  AppConfig.init(AppFlavor.vendor);

  // 2b. Analytics: tags every event with role=merchant (AppConfig must be set
  // first so the role is known).
  await Analytics.init();

  // 3. Determine Route
  final auth = AuthService.to;

  // Logic: If logged in, go to Merchant Shell. If not, go to Login.
  String initialRoute = auth.isLoggedIn 
      ? Routes.vendorShell 
      : Routes.roleLoginScreen;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NetCubit()..start()),
        BlocProvider(create: (_) => UpdateCubit()),
      ],
      child: KorraApp(
        initialRoute: initialRoute,
        appPages: VendorPages.routes, // 👈 Only Vendor + Common routes
        isMerchant: true, // 👈 3. PASS THIS FLAG
      ),
    ),
  );
}