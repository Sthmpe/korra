import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../../config/utils/korra_exception.dart';
import 'vendor_repository.dart';

extension PinRepository on VendorRepository {
  
  Future<void> setTransactionPin(String uid, String pin) async {
    try {
      final user = auth.currentUser;

      if (user == null) throw "You must be logged in.";

      // 1. Get the User VIP Pass (Who they are)
      final idToken = await user.getIdToken(true);

      // 2. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("User ID: ${user.uid}");
      debugPrint("🔒 Calling vendor-transaction-ops with Double Lock...");

      final response = await fx.invoke(
        'vendor-transaction-ops',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
        },
        body: {
          'type': 'create_pin',
          'uid': uid,
          'pin': pin, 
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? "Failed to set PIN");
      }
    } catch (e) {
      // Reuse the logic or a simple translator
      final msg = e.toString().toLowerCase();
      
      if (msg.contains('socketexception')) {
        throw KorraException(
          "Connection failed. Could not save your PIN.",
          technicalDetails: "Network Error",
        );
      }
      
      throw KorraException(
        "We couldn't verify your PIN securely. Please try again.",
        technicalDetails: e.toString(),
      );
    }
  }
}