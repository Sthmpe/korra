// import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'vendor_repository.dart';

extension TransferRepository on VendorRepository {

  /// Authorize transfer with OTP
  Future<String> authorizeTransferOtp({
    required String reference,
    required String authorizationCode,
  }) async {
    final result = await monnify.authorizeTransferOtp(
      reference: reference,
      authorizationCode: authorizationCode,
    );

    if (result['ok'] != true) {
      throw Exception(result['message'] ?? 'OTP authorization failed');
    }

    return result['status']; // e.g. "SUCCESS" | "FAILED"
  }

  /// Resend transfer OTP
  Future<Map<String, String>> resendTransferOtp({
    required String reference,
  }) async {
    try {
      final result = await monnify.resendTransferOtp(reference: reference);
      // result looks like { status: "SUCCESS", message: "..." }
      return {
        'status': result['status'] as String,
        'message': result['message'] as String,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Check status of a transfer
  Future<Map<String, dynamic>> checkTransferStatus(String reference) async {
    try {
      final result = await monnify.checkTransferStatus(reference: reference);
      return {
        'status': result['status'],
        'fee': result['fee'],
        'createdOn': result['createdOn'],
      }; // e.g. SUCCESS, FAILED, PENDING
    } catch (e) {
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

  Future<void> saveTransaction(
    String vendorId,
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    await firestore
        .collection('transactions')
        .doc(vendorId)
        .collection(
          'vendor_transactions',
        ) // 👈 optional if you want sub-collection
        .doc(transactionId)
        .set({
          ...data,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> updateTransactionStatus(
    String vendorId,
    String transactionId,
    String status,
  ) async {
    await firestore
        .collection('transactions')
        .doc(vendorId)
        .collection('vendor_transactions')
        .doc(transactionId)
        .update({"status": status, "updatedAt": FieldValue.serverTimestamp()});
  }
}