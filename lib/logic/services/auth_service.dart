import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/constants/prefs_keys.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  // Variables we can access INSTANTLY
  String? uid;
  String? role;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<AuthService> init() async {
    // 1. Check Firebase User
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // 2. Load Local Data
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString(PrefsKeys.userUid);
      role = prefs.getString(PrefsKeys.userRole);

      // Security Check: If Firebase UID doesn't match Local UID, clear everything
      if (uid != user.uid) {
        uid = null;
        role = null;
      }
    }
    return this;
  }
}