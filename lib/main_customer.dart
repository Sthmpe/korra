import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bootstrap.dart';
import 'config/routes/customer_pages.dart';
import 'config/routes/app_routes.dart';
import 'flavors/app_config.dart';
import 'korra_app.dart'; // ✅ Uses your existing KorraApp
import 'logic/core/net/net_cubit.dart';
import 'logic/core/update/update_cubit.dart';
import 'logic/services/auth_service.dart';
import 'logic/services/deep_link_service.dart';

void main() async {
  // 🚀 Capture the flag from the terminal command
  const bool isLive = bool.fromEnvironment('IS_LIVE', defaultValue: false);

  // 1. Run Shared Setup with the Live flag
  await bootstrap(isLive: isLive);

  // 2. Set Identity: CUSTOMER
  AppConfig.init(AppFlavor.customer);

  // 3. Determine Route
  final auth = AuthService.to;
  
  // Logic: If logged in, go to Shop. If not, go to Login.
  // We don't care about 'role' check here because this IS the customer app.
  String initialRoute = auth.isLoggedIn 
      ? Routes.customerShell 
      : Routes.roleLoginScreen;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NetCubit()..start()),
        BlocProvider(create: (_) => UpdateCubit()),
      ],
      // We pass the calculated route to your existing KorraApp
      child: KorraApp(
        initialRoute: initialRoute,
        appPages: CustomerPages.routes, // 👈 Only Customer + Common routes
        isMerchant: false,
      ),
    ),
  );

  // 🔗 App Links: route korra.com.ng/store/{slug} → storefront. Started after
  // the first frame so the GetX navigator exists before we route.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DeepLinkService.instance.start();
  });
}