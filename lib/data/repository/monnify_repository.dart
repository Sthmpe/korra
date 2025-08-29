import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app_secrets.dart';

class MonnifyRepository {
  final Dio _dio = Dio();
  final String _baseUrl = AppSecrets.monnifyBaseURL;
  final String _apiKey = AppSecrets.monnifyApiKey;
  final String _secretKey = AppSecrets.monnifySecretKey;
  String? _accessToken;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Authenticate and store token
  Future<void> authenticate() async {
    try {
      final credentials = '$_apiKey:$_secretKey';
      final encoded = base64Encode(utf8.encode(credentials));

      final response = await _dio.post(
        '$_baseUrl/api/v1/auth/login',
        options: Options(headers: {
          'Authorization': 'Basic $encoded',
          'Content-Type': 'application/json',
        }),
      );

      final data = response.data;

      if (data['requestSuccessful'] == true) {
        _accessToken = data['responseBody']['accessToken'];
      } else {
        throw Exception("Authentication failed: ${data['responseMessage']}");
      }
    } catch (e) {
      throw Exception('Error authenticating Monnify: $e');
    }
  }

  /// Get token or authenticate
  Future<String> getAccessToken() async {
    try {
      if (_accessToken == null) await authenticate();
      return _accessToken!;
    } catch (e) {
      throw Exception('Failed to retrieve access token: $e');
    }
  }

  /// Verify BVN details
  Future<void> verifyBVN({
    required String bvn,
    required String name,
    required String dateOfBirth,
    required String mobileNo,
    String? accessToken
  }) async {
    try {
      final token = accessToken ?? await getAccessToken();

      final response = await _dio.post(
        '$_baseUrl/api/v1/vas/bvn-details-match',
        data: {
          "bvn": bvn,
          "name": name,
          "dateOfBirth": dateOfBirth, // Format: "03-Oct-1993"
          "mobileNo": mobileNo,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      final data = response.data;

      if (data['requestSuccessful'] != true) {
        throw Exception(data['responseMessage'] ?? 'Invalid BVN provided');
      }

      final body = data['responseBody'];
      if (body == null || body.isEmpty) {
        throw Exception('BVN verification failed: Empty response body');
      }

      final matchPercent = body['name']?['matchPercentage'] ?? 0;

      if (matchPercent < 50) {
        throw Exception(
            'Name match too low: $matchPercent%. Minimum required is 50%.');
      }
    } catch (e) {
      throw Exception('Error verifying BVN: $e');
    }
  }

  /// Verify NIN
  Future<void> verifyNIN(String nin, {String? accessToken}) async {
    try {
      final token = accessToken ?? await getAccessToken();

      final response = await _dio.post(
        '$_baseUrl/api/v1/vas/nin-details',
        data: {'nin': nin},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      final data = response.data;

      if (data['requestSuccessful'] != true) {
        throw Exception(data['responseMessage'] ?? 'NIN not found.');
      }
    } catch (e) {
      throw Exception('Error verifying NIN: $e');
    }
  }

  /// Normalize string for matching (e.g., remove spaces, lowercase)
  String _normalizeName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  Future<void> getBanksAndSaveToFirestore({String? accessToken}) async {
    try {
      final token = accessToken ?? await getAccessToken();

      // 1. Fetch Monnify Banks
      final monnifyRes = await _dio.get(
        '$_baseUrl/api/v1/banks',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      final monnifyData = monnifyRes.data;
      if (monnifyData['requestSuccessful'] != true) {
        throw Exception("Failed to fetch Monnify banks");
      }

      final monnifyBanks =
          List<Map<String, dynamic>>.from(monnifyData['responseBody']);

      // 2. Fetch Bank Logos
      final logoRes = await _dio.get(
        'https://cdn.jsdelivr.net/gh/jsanwo64/Nigeria-Banks-Logo-API/Banks.json',
      );

      final logoBanks = List<Map<String, dynamic>>.from(logoRes.data);

      // 3. Match and Save
      for (var bank in monnifyBanks) {
        final name = bank['name'];
        final code = bank['code'];

        final logoMatch = logoBanks.firstWhere(
          (b) => _normalizeName(b['name'] ?? '') == _normalizeName(name),
          orElse: () => {},
        );

        final logoUrl = logoMatch['logo'] ?? '';

        await _firestore.collection('Banks').add({
          'name': name,
          'code': code,
          'logo': logoUrl,
        });
      }

      if (kDebugMode) print('✅ Banks saved to Firestore successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving banks to Firestore: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createWallet({
    required String walletReference,
    required String walletName,
    required String customerName,
    required String customerEmail,
    required String bvn,
    required String bvnDateOfBirth,
    String? accessToken,
  }) async {
    try {
      final token = accessToken ?? await getAccessToken();

      final response = await _dio.post(
        '$_baseUrl/api/v1/disbursements/wallet',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "walletReference": walletReference,
          "walletName": walletName,
          "customerName": customerName,
          "customerEmail": customerEmail,
          "bvnDetails": {
            "bvn": bvn,
            "bvnDateOfBirth": bvnDateOfBirth,
          },
        },
      );
      
      final data = response.data;

      if (data['requestSuccessful'] == true) {
        debugPrint("Wallet details: ${data['responseBody']}");
        return {
          'walletName': data['responseBody']['walletName'],
          'walletReference': data['responseBody']['walletReference'],
          'accountNumber': data['responseBody']['accountNumber'],
          'accountName': data['responseBody']['accountName'],
        };
      } else {
        throw Exception('Failed to create wallet: ${data['responseMessage']}');
      }
    } catch (e) {
      debugPrint("❌ Error creating wallet: $e");
      throw Exception("Wallet creation failed: $e");
    }
  }

  Future<num> getWalletBalance(String accountNumber, {String? accessToken}) async {
    final token = accessToken ?? await getAccessToken();

    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/disbursements/wallet/balance',
        queryParameters: {'accountNumber': accountNumber},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;

      if (data['requestSuccessful']) {
        final balance = data['responseBody']['availableBalance'];
        debugPrint('✅ Wallet Balance: $balance');
        return balance is num ? balance : num.parse(balance.toString());
      } else {
        throw Exception('Failed to fetch balance');
      }
    } catch (e) {
      rethrow;
    }
  }
}