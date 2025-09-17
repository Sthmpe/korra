import '../../../logic/bloc/vendor/payout/bank.dart';
import 'vendor_repository.dart';

extension BankRepository on VendorRepository {
  /// Verifies a bank account and returns the account holder's name.
  ///
  /// This method abstracts the underlying remote call and data parsing,
  /// providing a simple, clean interface for the business logic layer (BLoC).
  /// It returns only the essential piece of information needed: the verified name.
  /// On failure, it throws a clear exception.
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
      // This protects the app from unexpected data formats.
      final accountName = result['accountName'];
      if (accountName is String && accountName.isNotEmpty) {
        return accountName;
      } else {
        // This is a critical data integrity check.
        throw Exception('Account name not found in validation response.');
      }
    } catch (e) {
      // We re-throw a user-friendly error message.
      throw Exception('Could not verify account details. Please check the number and try again.');
    }
  }

  /// Fetches the list of all available banks for payout method setup.
  ///
  /// This method follows the clean architecture principle by calling the
  /// underlying MonnifyFunctions service, abstracting that implementation
  /// detail away from the BLoC and UI layers.
  Future<List<Bank>> getBankList() async {
    try {
      final banks = await monnify.getBankList();
      return banks;
    } catch (e) {
      // Provide a more specific error for this repository-level context.
      throw Exception('Could not retrieve the list of banks. Please try again.');
    }
  }


  /// Validate bank account (returns only account name + number)
  Future<Map<String, String>> validateBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final result = await monnify.validateBankAccount(
      accountNumber: accountNumber,
      bankCode: bankCode,
    );

    return {
      "accountNumber": result["accountNumber"],
      "accountName": result["accountName"],
    };
  }
}
