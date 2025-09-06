import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../logic/bloc/vendor/payout/bank.dart';

class MonnifyFunctions {
  final FunctionsClient _fx;
  MonnifyFunctions({FunctionsClient? fx})
    : _fx = fx ?? Supabase.instance.client.functions;

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

  /// Get Wallets
  /// Response:
  /// {
  ///   "ok": true,
  ///   "wallets": [
  ///     {
  ///       "walletName": "...",
  ///       "walletReference": "...",
  ///       "customerName": "...",
  ///       "customerEmail": "...",
  ///       "accountNumber": "...",
  ///       "accountName": "...",
  ///       "topUpAccountDetails": {
  ///         "accountNumber": "...",
  ///         "bankName": "...",
  ///         "bankCode": "..."
  ///       }
  ///     }
  ///   ]
  /// }
  Future<List<Map<String, dynamic>>> fetchWallets({
    int pageSize = 10,
    int pageNo = 0,
  }) async {
    try {
      final res = await _fx.invoke(
        'get-wallets',
        method: HttpMethod.get,
        queryParameters: {
          'pageSize': pageSize.toString(),
          'pageNo': pageNo.toString(),
        },
      );

      final data = res.data;

      if (data == null || data['ok'] != true) {
        if (data != null && data.containsKey('monnifyError')) {
          final monnifyError = data['monnifyError'];
          final message =
              monnifyError['responseMessage'] ?? 'Unknown Monnify error';
          final code = monnifyError['responseCode'] ?? 'N/A';
          throw Exception("Monnify Error: $message (Code: $code)");
        }
        throw Exception("Error fetching wallets: ${data?['message']}");
      }

      final wallets = List<Map<String, dynamic>>.from(data['wallets'] ?? []);
      debugPrint("Fetched ${wallets.length} wallets");
      return wallets;
    } catch (e) {
      debugPrint("Error fetching wallets: $e");
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

  /// Create Reserved Account
  /// Response:
  /// {
  ///   "ok": true,
  ///   "accountReference": "abc1niui23",
  ///   "accountName": "MARVELOUS BENJI",
  ///   "accountNumber": "6839490147",
  ///   "bankName": "Moniepoint Microfinance Bank",
  ///   "bankCode": "50515",
  ///   "currencyCode": "NGN",
  ///   "customerEmail": "test@tester.com",
  ///   "status": "ACTIVE"
  /// }
  Future<Map<String, dynamic>> createReservedAccount({
    required String accountReference,
    required String accountName,
    required String currencyCode,
    required String contractCode,
    required String customerEmail,
    String? customerName,
    String? bvn,
    String? nin,
    List<Map<String, dynamic>>? incomeSplitConfig,
  }) async {
    final res = await _fx.invoke(
      'create-reserved-account',
      body: {
        'accountReference': accountReference,
        'accountName': accountName,
        'currencyCode': currencyCode,
        'contractCode': contractCode,
        'customerEmail': customerEmail,
        'customerName': customerName,
        'bvn': bvn,
        'nin': nin,
        'incomeSplitConfig': incomeSplitConfig ?? [],
      },
    );

    final data = res.data;
    if (data == null || data['ok'] != true) {
      throw Exception(data?['message'] ?? 'Reserved account creation failed');
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
    final res = await _fx.invoke(
      'validate-bank-account',
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
      'initiate-transfer',
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

  /// Get Wallet Transactions
  /// Response:
  /// {
  ///   "ok": true,
  ///   "transactions": [
  ///     {
  ///       "reference": "MFDS50220230918031834001322SW440P",
  ///       "amount": 2500000,
  ///       "type": "DEBIT",
  ///       "status": "COMPLETED",
  ///       "date": "2023-09-18T14:18:34.751+0000",
  ///       "narration": null
  ///     },
  ///     ...
  ///   ]
  /// }
  Future<List<Map<String, dynamic>>> getWalletTransactions({
    required String accountNumber,
  }) async {
    final res = await _fx.invoke(
      'get-wallet-transactions',
      method: HttpMethod.get,
      queryParameters: {"accountNumber": accountNumber},
    );

    if (res.data == null || res.data['ok'] != true) {
      throw Exception(
        res.data?['message'] ?? 'Failed to fetch wallet transactions',
      );
    }

    return List<Map<String, dynamic>>.from(res.data['transactions']);
  }

  /// Get Wallet Balance
  /// Example Response:
  /// {
  ///   "ok": true,
  ///   "availableBalance": 5000000000
  /// }
  Future<Map<String, dynamic>> getWalletBalance({
    required String accountNumber,
  }) async {
    final res = await _fx.invoke(
      'get-wallet-balance',
      method: HttpMethod.get,
      queryParameters: {"accountNumber": accountNumber},
    );

    if (res.data == null || res.data['ok'] != true) {
      throw Exception(res.data?['message'] ?? 'Failed to fetch wallet balance');
    }

    return Map<String, dynamic>.from(res.data);
  }

  /// 🔐 Create Wallet
  ///
  /// Response format on success:
  /// ```json
  /// {
  ///   "ok": true,
  ///   "walletName": "Staging Wallet - ref16804248425966",
  ///   "walletReference": "ref16842048425966",
  ///   "accountNumber": "1345947817",
  ///   "accountName": "Test01-John Doe"
  /// }
  /// ```
  ///
  /// On failure:
  /// ```json
  /// { "ok": false, "message": "Wallet creation failed" }
  /// ```
  Future<Map<String, dynamic>> createWallet({
    required String walletReference,
    required String walletName,
    required String customerName,
    required String customerEmail,
    required String bvn,
    required String bvnDateOfBirth, // "YYYY-MM-DD"
  }) async {
    final res = await _fx.invoke(
      'create-wallet',
      body: {
        'walletReference': walletReference,
        'walletName': walletName,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'bvn': bvn,
        'bvnDateOfBirth': bvnDateOfBirth,
      },
    );

    final ok = res.data is Map && (res.data['ok'] == true);
    if (!ok) throw Exception(_msg(res.data));

    return Map<String, dynamic>.from(res.data);
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
      final res = await _fx.invoke(
        'nin-verify', // Supabase Edge Function name
        body: {'nin': nin},
      );

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
    final res = await _fx.invoke(
      'bvn-verify',
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
