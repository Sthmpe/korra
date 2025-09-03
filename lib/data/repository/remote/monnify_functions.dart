import 'package:supabase_flutter/supabase_flutter.dart';

class MonnifyFunctions {
  final FunctionsClient _fx;
  MonnifyFunctions({FunctionsClient? fx}) : _fx = fx ?? Supabase.instance.client.functions;

  Future<void> verifyNin(String nin) async {
    final res = await _fx.invoke('nin-verify', body: {'nin': nin});
    final ok = res.data is Map && (res.data['success'] == true);
    if (!ok) throw Exception(_msg(res.data));
  }

  Future<void> verifyBvn({
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
    final ok = res.data is Map && (res.data['success'] == true);
    if (!ok) throw Exception(_msg(res.data));
  }

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
    final ok = res.data is Map && (res.data['success'] == true);
    if (!ok) throw Exception(_msg(res.data));
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  String _msg(dynamic data) {
    if (data is Map && data['error'] is Map) {
      final e = data['error'] as Map;
      return (e['message'] as String?) ?? 'Request failed';
    }
    return 'Request failed';
  }
}
