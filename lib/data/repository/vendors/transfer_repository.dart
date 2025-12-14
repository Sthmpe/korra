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
      final response = await fx.invoke(
        'vendor-transaction-ops',
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
        throw Exception(data['error'] ?? "Payout failed");
      }

      return {
        'reference': data['reference'],
        'status': 'success',
      };

    } catch (e) {
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