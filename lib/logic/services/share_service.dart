import 'package:share_plus/share_plus.dart';

class ShareService {
  // Prevent instantiation
  ShareService._();

  /// Shares a general referral message for vendors/friends.
  static Future<void> shareAppReferral({required String referrerName}) async {
    // Define your message and link here.
    // Ideally, the link is a deep link (e.g., https://korra.app/refer?user=123)
    const String appLink = "https://korra.app/join"; // Placeholder link

    final String message = 
      "Hey! I've been using Korra to easily reserve products. "
      "Vendors, join me on Korra to connect with more customers! \n\n"
      "Download here: $appLink";

    try {
      // This opens the native OS share sheet
      await Share.share(
        message,
        subject: 'Join me on Korra!', // Subject line for email apps
      );
    } catch (e) {
      // Handle rare platform failures quietly or log them
      print("Error sharing: $e");
    }
  }
}