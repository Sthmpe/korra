import 'vendor_repository.dart';

extension ReserveAccountRepository on VendorRepository {
  /// Fetch transactions for a reserved account
  Future<List<Map<String, dynamic>>> fetchReservedAccountTransactions({
    required String accountReference,
    int page = 0,
    int size = 10,
  }) async {
    final result = await monnify.getReservedAccountTransactions(
      accountReference: accountReference,
      page: page,
      size: size,
    );

    // Only return the transactions array
    final transactions = List<Map<String, dynamic>>.from(
      result["transactions"] ?? [],
    );
    return transactions;
  }

  /// Deallocate reserved account through Monnify
  Future<Map<String, dynamic>> deallocateReservedAccount({
    required String accountReference,
  }) async {
    final result = await monnify.deallocateReservedAccount(
      accountReference: accountReference,
    );

    // Only return confirmation of deallocation
    return {
      "accountReference": result["accountReference"],
      "status": result["status"], // "DEALLOCATED"
    };
  }

  /// Create Reserved Account through Monnify
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
    final result = await monnify.createReservedAccount(
      accountReference: accountReference,
      accountName: accountName,
      currencyCode: currencyCode,
      contractCode: contractCode,
      customerEmail: customerEmail,
      customerName: customerName,
      bvn: bvn,
      nin: nin,
      incomeSplitConfig: incomeSplitConfig,
    );

    // Only return the assigned account info
    return {
      "accountNumber": result["accountNumber"],
      "bankName": result["bankName"],
      "bankCode": result["bankCode"],
    };
  }
}
