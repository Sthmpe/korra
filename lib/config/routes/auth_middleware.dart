import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ If logged in, allow access
    if (user != null) return null;

    debugPrint("🛑 AUTH BLOCK: Access denied to $route. Sending to Login.");

    // ❌ If not logged in, send to RoleLoginScreen
    return RouteSettings(
      name: Routes.roleLoginScreen,
      arguments: {'redirect': route},
    );
  }
}
