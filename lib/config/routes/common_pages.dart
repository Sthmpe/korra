import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/auth/role_login/role_login_screen.dart';
import '../../presentation/auth/forgot_password/forgot_password_screen.dart';
import '../../presentation/auth/forgot_password/reset_link_sent_screen.dart';
import 'app_routes.dart';

Widget guard(Widget Function(dynamic args) builder) {
  final args = Get.arguments;
  if (args == null) {
    debugPrint("⚠️ Missing arguments. Redirecting to Login.");
    Future.microtask(() => Get.offAllNamed(Routes.roleLoginScreen));
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
  return builder(args);
}

final List<GetPage> commonRoutes = [
  GetPage(name: Routes.roleLoginScreen, page: () => const RoleLoginScreen()),
  GetPage(
    name: Routes.resetLinkSent,
    page: () => guard((args) => ResetLinkSentScreen(
      email: args['email'],
    )),
  ),
  GetPage(
    name: Routes.forgotPassword,
    page: () => const ForgotPasswordScreen(),
  ),
];
