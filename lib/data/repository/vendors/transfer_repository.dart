import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../../config/utils/korra_exception.dart';
import 'vendor_repository.dart';

extension TransferRepository on VendorRepository {
  
  // REQUEST PAYOUT
  Future<Map<String, dynamic>> requestPayout({
    required String uid,
    required double amount,
    required String pin,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final user = auth.currentUser;

      if (user == null) throw "You must be logged in.";

      // 1. Get the User VIP Pass (Who they are)
      final idToken = await user.getIdToken(true);
      debugPrint("ID Token acquired for payout: $idToken\n");

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
          'firebase-token': 'Bearer $idToken',
        },
        body: {
          'type': 'transfer',
          'uid': uid,
          'pin': pin,
          'amount': amount,
          'destination': {
            'bankCode': bankCode,
            'accountNumber': accountNumber,
            'accountName': accountName,
          }
        },
      );

      // 1. Check for Edge Function Logic Errors
      final data = response.data;
      if (data['success'] != true) {
        // Pass the server error message to the catch block
        throw Exception(data['error'] ?? data['message'] ?? "Payout failed");
      }

      return {
        'reference': data['reference'],
        'status': 'success',
      };

    } catch (e) {
      debugPrint('Payout Error: $e');
      throw _translatePayoutError(e);
    }
  }

  // --- HELPER: PAYOUT ERROR TRANSLATOR ---
  KorraException _translatePayoutError(Object error) {
    final msg = error.toString().toLowerCase();

    // 1. PIN Errors
    if (msg.contains('incorrect pin')) {
      return KorraException(
        "The PIN you entered is incorrect.",
        technicalDetails: "Auth Failure",
      );
    }
    if (msg.contains('pin not set')) {
      return KorraException(
        "You haven't set a transaction PIN yet.",
        technicalDetails: "Security Config Missing",
      );
    }

    // 2. Money Errors
    if (msg.contains('insufficient funds')) {
      // The server usually sends "Insufficient funds. Balance: 5000"
      // We strip the technical details for the main message
      return  KorraException(
        "You do not have enough withdrawable funds for this amount.",
        technicalDetails: "Overdraft Attempt",
      );
    }

    // 3. Technical/Network
    if (msg.contains('socketexception') || msg.contains('network request failed')) {
      return KorraException(
        "We couldn't connect to the server. Please check your internet.",
        technicalDetails: "Network Error",
      );
    }
    
    if (msg.contains('gateway error')) {
      return KorraException(
        "The banking network is currently fluctuating. Please try again later.",
        technicalDetails: "Monnify/Gateway Error",
      );
    }

    // 4. Default
    return KorraException(
      "Transaction failed. Please try again.",
      technicalDetails: error.toString(),
    );
  }
}