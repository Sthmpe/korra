import 'package:supabase_flutter/supabase_flutter.dart';

class MonnifyFunctions {
  final FunctionsClient _fx;
  MonnifyFunctions({FunctionsClient? fx}) : _fx = fx ?? Supabase.instance.client.functions;

  /// 🔎 Verify NIN
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "ok": true,
  ///   "message": "NIN verification completed",
  ///   "nin": "12345678901",
  ///   "name": "John Doe",
  ///   "dob": "1993-10-03",
  ///   "mobile": "08012345678"
  /// }
  /// ```
  /// Or on failure:
  /// ```json
  /// { "ok": false, "message": "Invalid NIN" }
  /// ```
  Future<Map<String, dynamic>> verifyNin(String nin) async {
    final res = await _fx.invoke('nin-verify', body: {'nin': nin});
    final ok = res.data is Map && (res.data['ok'] == true);
    if (!ok) throw Exception(_msg(res.data));
    return Map<String, dynamic>.from(res.data);
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
    final res = await _fx.invoke('bvn-verify', body: {
      'bvn': bvn,
      'name': name,
      'dateOfBirth': dateOfBirthIso,
      'mobileNo': mobileNo,
    });
    final ok = res.data is Map && (res.data['ok'] == true);
    if (!ok) throw Exception(_msg(res.data));
    return Map<String, dynamic>.from(res.data);
  }

  /// 🏦 Create Wallet
  ///
  /// Response format:
  /// ```json
  /// {
  ///   "ok": true,
  ///   "message": "Wallet created",
  ///   "walletName": "Customer Wallet",
  ///   "walletReference": "WALLET-REF-123",
  ///   "accountNumber": "1234567890",
  ///   "accountName": "John Doe"
  /// }
  /// ```
  /// Or on failure:
  /// ```json
  /// { "ok": false, "message": "Create wallet failed" }
  /// ```
  Future<Map<String, dynamic>> createWallet({
    required String walletReference,
    required String walletName,
    required String customerName,
    required String customerEmail,
    required String bvn,
    required String bvnDateOfBirthIso, // "YYYY-MM-DD"
  }) async {
    final res = await _fx.invoke('wallet-create', body: {
      'walletReference': walletReference,
      'walletName': walletName,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'bvn': bvn,
      'bvnDateOfBirth': bvnDateOfBirthIso,
    });
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
