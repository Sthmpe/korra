import 'package:flutter/foundation.dart';

import '../../../config/utils/korra_exception.dart';
import '../../../logic/bloc/vendor/payout/bank.dart';
import 'vendor_repository.dart';

extension BankRepository on VendorRepository {
  /// Verifies a bank account and returns the account holder's name.
  ///
  /// This method abstracts the underlying remote call and data parsing,
  /// providing a simple, clean interface for the business logic layer (BLoC).
  /// It returns only the essential piece of information needed: the verified name.
  /// On failure, it throws a clear exception.
  // ===========================================================================
  // 1. VERIFY BANK ACCOUNT (Returns Name)
  // ===========================================================================
  Future<String> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      final result = await monnify.validateBankAccount(
        accountNumber: accountNumber,
        bankCode: bankCode,
      );

      // We ensure the 'accountName' field exists and is a string before returning.
      final accountName = result['accountName'];
      if (accountName is String && accountName.isNotEmpty) {
        return accountName;
      } else {
        // Critical data integrity check failed
        throw KorraException(
          'Verification failed: Could not retrieve the account holder\'s name.',
          technicalDetails: 'Missing or empty accountName in Monnify response.',
        );
      }
    } catch (e) {
      debugPrint('❌ Verify Bank Account Failed (Technical): $e');
      
      // If Monnify throws a specific error message (e.g., 'Account not found'), translate it.
      if (e.toString().contains('Account not found')) {
        throw KorraException(
          'Account number is invalid or not recognized by the bank.',
          technicalDetails: e.toString(),
        );
      }
      
      // Catch all other errors (Network, timeout, unknown API error)
      if (e is KorraException) rethrow;

      throw KorraException(
        'Could not verify account details. Please check the number and bank and try again.',
        technicalDetails: e.toString(),
      );
    }
  }

  /// Fetches the list of all available banks for payout method setup.
  ///
  /// This method follows the clean architecture principle by calling the
  /// underlying MonnifyFunctions service, abstracting that implementation
  /// detail away from the BLoC and UI layers.
  // ===========================================================================
  // 2. GET BANK LIST
  // ===========================================================================
  Future<List<Bank>> getBankList() async {
    try {
      final banks = await monnify.getBankList();
      return banks;
    } catch (e) {
      debugPrint('❌ Fetch Bank List Failed (Technical): $e');
      
      if (e is KorraException) rethrow;

      throw KorraException(
        'Could not retrieve the list of banks. Please check your internet connection.',
        technicalDetails: e.toString(),
      );
    }
  }

  // ===========================================================================
  // 3. VALIDATE BANK ACCOUNT (Returns Name + Number Map)
  // ===========================================================================
  Future<Map<String, String>> validateBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      final result = await monnify.validateBankAccount(
        accountNumber: accountNumber,
        bankCode: bankCode,
      );

      // We perform basic data checks here just in case the service returns nulls.
      final accountName = result["accountName"] as String?;
      final accNumber = result["accountNumber"] as String?;
      
      if (accountName == null || accNumber == null) {
          throw KorraException(
             'Incomplete validation data received. Account name or number is missing.',
             technicalDetails: 'Monnify response missing expected keys: ${result.keys}',
          );
      }
      
      return {
        "accountNumber": accNumber,
        "accountName": accountName,
      };
      
    } catch (e) {
      debugPrint('❌ Validate Bank Account Failed (Technical): $e');
      
      // Catch Monnify/business errors (e.g., account not found)
      if (e.toString().contains('Account not found')) {
        throw KorraException(
          'Account details are incorrect or could not be found.',
          technicalDetails: e.toString(),
        );
      }
      
      if (e is KorraException) rethrow;
      
      throw KorraException(
        'Failed to validate account. Please check inputs.',
        technicalDetails: e.toString(),
      );
    }
  }
}
