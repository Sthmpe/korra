import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../logic/bloc/vendor/payout/bank.dart';

class MonnifyFunctions {
  final FunctionsClient _fx;
  MonnifyFunctions({FunctionsClient? fx})
    : _fx = fx ?? Supabase.instance.client.functions;

  final korraSecret = "7f8a9b2d4c6e1f3a5b7c9d0e2f4a6b8c1d3e5f7a9b0c2d4e6f8a1b3c5d7e9f0a";


  /// Call the OTP authorization function
  Future<Map<String, dynamic>> authorizeTransferOtp({
    required String reference,
    required String authorizationCode,
  }) async {
    final res = await _fx.invoke(
      'authorize-transfer-otp',
      body: {'reference': reference, 'authorizationCode': authorizationCode},
    );

    final data = res.data;
    if (data == null) {
      throw Exception('No response from server');
    }

    return data; // { ok: true, status: "SUCCESS", message: ... }
  }

  /// Resend OTP for transfer
  Future<Map<String, dynamic>> resendTransferOtp({
    required String reference,
  }) async {
    final res = await _fx.invoke(
      'resend-transfer-otp',
      body: {'reference': reference},
    );

    final data = res.data;
    if (data == null || data['ok'] != true) {
      final message = data != null && data.containsKey('message')
          ? data['message']
          : 'Resend OTP failed';
      throw Exception(message);
    }

    // Return normalized response
    return {
      'status': data['status'], // e.g. "SUCCESS"
      'message': data['message'], // e.g. "Authorization code will be processed..."
    };
  }

  /// 🏦 Fetches the curated list of banks from the Supabase database.
  ///
  /// This function calls the `get-banks-supabase` Edge Function, which reads
  /// directly from the `banks` table that is periodically updated by the
  /// `sync-banks` scheduled job. This approach ensures a fast, efficient,
  /// and reliable data fetch for the client application.
  ///
  /// Response format on success:
  /// ```json
  /// {
  ///   "ok": true,
  ///   "banks": [
  ///     {
  ///       "name": "Access Bank",
  ///       "code": "000014",
  ///       "logo_url": "[https://example.com/logo.png](https://example.com/logo.png)"
  ///     },
  ///     ...
  ///   ]
  /// }
  /// ```
  Future<List<Bank>> getBankList() async {
    try {
      final res = await _fx.invoke(
        'get-banks-supabase', // The name of your new, fast function
        method: HttpMethod.get,
      );

      final data = res.data;

      // Rigorous checking ensures data integrity, a hallmark of a world-class app.
      if (data == null || data['ok'] != true || data['banks'] is! List) {
        throw Exception('Failed to retrieve bank list');
      }

      // We safely cast and map the raw data into a strongly-typed list
      // of Bank objects, ensuring type safety throughout the app.
      final bankData = List<Map<String, dynamic>>.from(data['banks']);
      final banks = bankData.map((map) => Bank.fromMap(map)).toList();

      return banks;
    } catch (e) {
      debugPrint("Error fetching bank list: $e");
      // Re-throwing allows the BLoC layer to catch and handle the error gracefully.
      rethrow;
    }
  }



  /// Get Reserved Account Transactions
  /// Response:
  /// {
  ///   "ok": true,
  ///   "transactions": [ ... ]  // list of transaction objects
  /// }
  Future<Map<String, dynamic>> getReservedAccountTransactions({
    required String accountReference,
    int page = 0,
    int size = 10,
  }) async {
    final res = await _fx.invoke(
      'reserved-account-transactions',
      body: {'accountReference': accountReference, 'page': page, 'size': size},
    );

    final data = res.data;
    if (data == null || data['ok'] != true) {
      throw Exception(
        data?['message'] ?? "Failed to fetch reserved account transactions",
      );
    }

    return Map<String, dynamic>.from(data);
  }

  /// Deallocate Reserved Account
  /// Response:
  /// {
  ///   "ok": true,
  ///   "accountReference": "abc1niui23",
  ///   "status": "DEALLOCATED"
  /// }
  Future<Map<String, dynamic>> deallocateReservedAccount({
    required String accountReference,
  }) async {
    final res = await _fx.invoke(
      'deallocate-reserved-account',
      body: {'accountReference': accountReference},
    );

    final data = res.data;
    if (data == null || data['ok'] != true) {
      throw Exception(
        data?['message'] ?? "Failed to deallocate reserved account",
      );
    }

    return Map<String, dynamic>.from(data);
  }


  /// Validate Bank Account through Monnify
  /// Response will look like:
  /// {
  ///   "ok": true,
  ///   "accountNumber": "0123456789",
  ///   "accountName": "Damilare Ogunnaike",
  ///   "bankCode": "057"
  /// }
  Future<Map<String, dynamic>> validateBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

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
    debugPrint("🔒 Calling validate-bank-account with Double Lock...");

    final res = await _fx.invoke(
      'validate-bank-account',
      headers: {
        'firebase-token': 'Bearer $idToken', // 🔐 Protect Monnify API limits!
        'x-korra-timestamp': timestamp,
        'x-korra-signature': signature,
      },
      body: {'accountNumber': accountNumber, 'bankCode': bankCode},
    );
    
    final data = res.data;
    if (data == null || data['ok'] != true) {
      throw Exception(data?['message'] ?? "Bank account validation failed");
    }
    return Map<String, dynamic>.from(data);
  }

  /// Check transfer status
  /// {
  ///   "ok": true,
  ///   "reference": "referen00ce---1290034",
  ///   "amount": 200,
  ///   "fee": 35,
  ///   "status": "SUCCESS",
  ///   "transactionDescription": "Transaction successful",
  ///   "transactionReference": "MFDS20220731033133AABQGN",
  ///   "beneficiary": {
  ///     "name": "Marvelous Benji",
  ///     "bank": "Zenith bank",
  ///     "accountNumber": "2085886393",
  ///     "bankCode": "057"
  ///   },
  ///   "createdOn": "2022-07-31T14:31:34.000+0000"
  /// }
  Future<Map<String, dynamic>> checkTransferStatus({
    required String reference,
  }) async {
    final res = await _fx.invoke(
      'check-transfer-status',
      body: {'reference': reference},
    );

    final data = res.data;
    if (data == null || data['ok'] != true) {
      throw Exception(data?['message'] ?? "Transfer status check failed");
    }
    return data;
  }

  /// Initiate a transfer to a bank account
  ///
  /// Response format:
  /// {
  ///   "ok": true,
  ///   "amount": 200,
  ///   "reference": "referen00ce---1290034",
  ///   "status": "SUCCESS",
  ///   "fee": 35,
  ///   "beneficiary": {
  ///      "name": "Marvelous Benji",
  ///      "bank": "Zenith bank",
  ///      "accountNumber": "2085886393",
  ///      "bankCode": "057"
  ///   },
  ///   "dateCreated": "2022-07-31T14:31:33.759+0000"
  /// }
  Future<Map<String, dynamic>> initiateTransfer({
    required double amount,
    required String reference,
    required String narration,
    required String destinationBankCode,
    required String destinationAccountNumber,
    required String currency,
    required String sourceAccountNumber,
  }) async {
    final res = await _fx.invoke(
      'initiate-transfer-single',
      body: {
        "amount": amount,
        "reference": reference,
        "narration": narration,
        "destinationBankCode": destinationBankCode,
        "destinationAccountNumber": destinationAccountNumber,
        "currency": currency,
        "sourceAccountNumber": sourceAccountNumber,
      },
    );

    return res.data as Map<String, dynamic>;
  }

  
  /// Verify NIN through Monnify Supabase Function
  /// ✅ On success:
  /// {
  ///   "ok": true,
  ///   "nin": "91919191913",
  ///   "firstName": "BENJAMIN",
  ///   "middleName": "CHUKS",
  ///   "lastName": "WILES",
  ///   "dateOfBirth": "1996-10-08",
  ///   "gender": "OTHER",
  ///   "mobileNumber": "2348107248890"
  /// }
  ///
  /// ❌ On failure:
  /// {
  ///   "ok": false,
  ///   "message": "NIN not found. Please check and try again."
  /// }
  Future<void> verifyNin(String nin) async {
    try {
      // 1. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("🔒 Calling nin-verify with Lock...");

      final res = await _fx.invoke(
        'nin-verify',
        headers: {
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        }, 
        body: {
          'nin': nin
        });

      final data = res.data as Map<String, dynamic>?;

      if (data == null || data['ok'] != true) {
        final msg = data?['message'] ?? 'NIN verification failed';
        throw Exception(msg);
      }

      debugPrint(
        "NIN verified successfully for ${data['firstName']} ${data['lastName']}",
      );
      return; // Success
    } catch (e) {
      debugPrint("NIN verification failed: $e");
      throw Exception("NIN verification failed: $e");
    }
  }

  /// 🔎 Verify BVN
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "ok": true,
  ///   "message": "BVN verification completed",
  ///   "bvn": "22228945899",
  ///   "nameMatch": "PARTIAL_MATCH",
  ///   "nameMatchPercent": 66,
  ///   "dobMatch": "NO_MATCH",
  ///   "mobileMatch": "FULL_MATCH"
  /// }
  /// ```
  /// Or on failure:
  /// ```json
  /// { "ok": false, "message": "Unable to process request. Invalid BVN provided" }
  /// ```
  Future<Map<String, dynamic>> verifyBvn({
    required String bvn,
    required String name,
    required String dateOfBirthIso, // "YYYY-MM-DD"
    required String mobileNo,
  }) async {
    // 1. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Do the Math: Hash the timestamp using the secret key
    final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
    final digest = hmacSha256.convert(utf8.encode(timestamp));
    final signature = digest.toString();

    debugPrint("🔒 Calling bvn-verify with Lock...");

    final res = await _fx.invoke(
      'bvn-verify',
      headers: {
        'x-korra-timestamp': timestamp,
        'x-korra-signature': signature,
      },
      body: {
        'bvn': bvn,
        'name': name,
        'dateOfBirth': dateOfBirthIso,
        'mobileNo': mobileNo,
      },
    );
    final ok = res.data is Map && (res.data['ok'] == true);
    if (!ok) throw Exception(_msg(res.data));
    return Map<String, dynamic>.from(res.data);
  }

  String _msg(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Request failed';
  }
}
