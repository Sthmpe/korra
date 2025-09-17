// import 'package:flutter/foundation.dart';

import 'vendor_repository.dart';

extension TransferRepository on VendorRepository {
  /// Check status of a transfer
  Future<String> checkTransferStatus(String reference) async {
    try {
      final result = await monnify.checkTransferStatus(reference: reference);
      //debugPrint("Transfer ${result['reference']} status: ${result['status']}");
      return result['status']; // e.g. SUCCESS, FAILED, PENDING
    } catch (e) {
      //debugPrint("Check transfer status failed: $e");
      rethrow;
    }
  }

  /// Initiate a transfer
  Future<Map<String, dynamic>> initiateTransfer({
    required double amount,
    required String reference,
    required String narration,
    required String destinationBankCode,
    required String destinationAccountNumber,
    String currency = "NGN",
    required String sourceAccountNumber,
  }) async {
    return await monnify.initiateTransfer(
      amount: amount,
      reference: reference,
      narration: narration,
      destinationBankCode: destinationBankCode,
      destinationAccountNumber: destinationAccountNumber,
      currency: currency,
      sourceAccountNumber: sourceAccountNumber,
    );
  }
}