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
      // 1. Prepare the Message (Updated Brand-Aligned Copy)
      final String text =
          "Hey! $referrerName invited you to join Korra.\n\n"
          "Your bridge to ownership.\n"
          "Reserve today. Complete at your pace.\n\n"
          "Download Korra: https://korra.com.ng";

      // 2. Load the Image from Assets
      final ByteData bytes =
          await rootBundle.load('assets/images/korra_invite.webp');
      final Uint8List list = bytes.buffer.asUint8List();

      // 3. Create a Temporary File for the Image
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/korra_invite.webp').create();
      await file.writeAsBytes(list);

      // 4. Share the File + Text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Join Korra',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');

      // Fallback: Share text only (Brand Consistent)
      Share.share(
        "$referrerName invited you to Korra.\n\n"
        "Reserve today. Complete at your pace.\n\n"
        "https://korra.com.ng",
      );
    }
  }
}
