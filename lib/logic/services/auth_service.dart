import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/constants/prefs_keys.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  // Variables we can access INSTANTLY
  String? uid;
  String? role;
  
  // 🚀 UPGRADED: Only returns true if they have a Firebase session AND finished signup
  bool get isLoggedIn => uid != null && FirebaseAuth.instance.currentUser != null;

  Future<AuthService> init() async {
    // 1. Check Firebase User
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // 2. Load Local Data
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString(PrefsKeys.userUid);
      role = prefs.getString(PrefsKeys.userRole);

      // 3. 🧟 ZOMBIE CHECK & SECURITY CHECK
      // If no local UID exists (they abandoned signup) OR the UIDs don't match
      if (uid == null || uid != user.uid) {
        debugPrint("🧟 Zombie session caught in AuthService! Wiping...");
        
        try {
          await GoogleSignIn.instance.signOut();
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          debugPrint("Failed to clear zombie session: $e");
        }
        
        // Reset variables so the app knows they are completely logged out
        uid = null;
        role = null;
      }
    }
    return this;
  }
}