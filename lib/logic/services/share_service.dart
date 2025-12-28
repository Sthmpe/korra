import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  // Prevent instantiation
  ShareService._();

  /// Shares the Korra Referral Image + Text
  static Future<void> shareAppReferral({required String referrerName}) async {
    try {
      // 1. Prepare the Message
      final String text = 
          "Hey! $referrerName is inviting you to join Korra.\n\n"
          "Secure your purchases and lock prices against inflation.\n"
          "Download the app now: https://korra.com.ng"; 

      // 2. Load the Image from Assets
      // ✅ UPDATED: Loading the specific WebP file
      final ByteData bytes = await rootBundle.load('assets/images/korra_invite.webp');
      final Uint8List list = bytes.buffer.asUint8List();

      // 3. Create a Temporary File for the Image
      final tempDir = await getTemporaryDirectory();
      // ✅ UPDATED: Saving as .webp in the temp folder so the OS recognizes it
      final file = await File('${tempDir.path}/korra_invite.webp').create();
      await file.writeAsBytes(list);

      // 4. Share the File + Text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Join Korra', 
      );
      
    } catch (e) {
      debugPrint('Error sharing: $e');
      // Fallback: If image fails, just share text
      Share.share(
          "Join $referrerName on Korra! Lock prices today. https://korra.com.ng");
    }
  }
}