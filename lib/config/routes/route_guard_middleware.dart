import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../../logic/services/auth_service.dart'; // Import Service

class RouteGuardMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (Get.arguments == null) {
      debugPrint("🚫 GUARD: Blocked direct access to $route.");

      // 🚀 USE SERVICE TO CHECK ROLE INSTANTLY
      final role = AuthService.to.role;

      if (role == 'vendor') {
        return const RouteSettings(name: Routes.vendorShell);
      } else if (role == 'customer') {
        return const RouteSettings(name: Routes.customerShell);
      } else {
        // If role is missing/unknown, safe fallback to Login
        return const RouteSettings(name: Routes.roleLoginScreen);
      }
    }
    return null;
  }
}
