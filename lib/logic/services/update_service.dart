import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UpdateCheckResult> check() async {
    try {
      // 1. Fetch Config
      final doc = await _db.collection('settings').doc('config').get();
      if (!doc.exists) return UpdateCheckResult.allowed();

      final data = doc.data()!;
      
      // 2. Master Switch
      final bool forceUpdate = data['force_update'] ?? false;
      if (!forceUpdate) return UpdateCheckResult.allowed();

      // 3. Get Current App Version
      final packageInfo = await PackageInfo.fromPlatform();
      final Version currentVersion = Version.parse(packageInfo.version);

      // 4. Get Required Version
      String minVersionStr = "1.0.0";
      
      if (Platform.isAndroid) {
        minVersionStr = data['min_version_android'] ?? '1.0.0';
      } else if (Platform.isIOS) {
        minVersionStr = data['min_version_ios'] ?? '1.0.0';
      }

      final Version minVersion = Version.parse(minVersionStr);

      // 5. Compare
      if (currentVersion < minVersion) {
        String? targetUrl;
        
        if (Platform.isAndroid) {
          final String? storeUrl = data['store_url_android'];
          // ✅ Smart Fallback: Use Store if available, else Direct APK
          if (storeUrl != null && storeUrl.isNotEmpty) {
            targetUrl = storeUrl;
          } else {
            targetUrl = data['direct_download_url'];
          }
        } else if (Platform.isIOS) {
          // iOS users usually go to TestFlight or Web
          targetUrl = data['store_url_ios'] ?? "https://korra.com.ng"; 
        }

        return UpdateCheckResult.blocked(
          updateUrl: targetUrl ?? "https://korra.com.ng",
          latestVersion: data['latest_version_code'] ?? minVersionStr,
        );
      }

      return UpdateCheckResult.allowed();
    } catch (e) {
      debugPrint("⚠️ Update Check Failed (Offline?): $e");
      // Always fail OPEN (Let them use the app if check fails)
      return UpdateCheckResult.allowed();
    }
  }
}

class UpdateCheckResult {
  final bool isBlocked;
  final String? updateUrl;
  final String? latestVersion;

  UpdateCheckResult({required this.isBlocked, this.updateUrl, this.latestVersion});

  factory UpdateCheckResult.allowed() => UpdateCheckResult(isBlocked: false);
  
  factory UpdateCheckResult.blocked({required String updateUrl, required String latestVersion}) => 
      UpdateCheckResult(isBlocked: true, updateUrl: updateUrl, latestVersion: latestVersion);
}