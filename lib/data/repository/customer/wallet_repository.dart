import 'package:korra/data/models/customer/customer_model.dart';
import 'package:korra/data/models/customer/topup/topup_details.dart';
import 'package:korra/data/repository/customer/customer_repository.dart';
import 'package:korra/data/repository/customer/topup_repository.dart';

extension WalletRepository on CustomerRepository {
  /// Fetch all wallets created by the merchant
  // Future<void> fetchWallets({int pageSize = 10, int pageNo = 0}) async {
  //   final wallets = await monnify.fetchWallets(
  //     pageSize: pageSize,
  //     pageNo: pageNo,
  //   );

  //   // debugPrint("Total wallets: ${wallets.length}");
  //   for (var wallet in wallets) {
  //     // debugPrint("Wallet Details:");
  //     // Use jsonEncode to print the entire wallet map as a formatted string
  //     // debugPrint(jsonEncode(wallet));
  //     // debugPrint("---"); // Optional separator for readability
  //   }
  // }

  /// Get wallet balance
  Future<num> getWalletBalance(String accountNumber) async {
    final data = await monnify.getWalletBalance(accountNumber: accountNumber);
    return (data['availableBalance'] as num?) ?? 0;
  }

  
  Future<void> updateAvailableBalance(
    String customerUid,
    String walletAccountNumber,
  ) async {
    final data = await monnify.getWalletBalance(
      accountNumber: walletAccountNumber,
    );
    final balance = data['availableBalance'] as num? ?? 0;

    final repository = CustomerRepository();
    final currentDetails = await repository.getTopUpDetails(customerUid);

    if (currentDetails != null) {
      // Update only the withdrawable balance, keep other details
      final updatedDetails = TopUpDetails(
        availableBalance: balance,
        walletAccountNumber: currentDetails.walletAccountNumber,
        walletAccountName: currentDetails.walletAccountName,
        walletAccountReference: currentDetails.walletAccountReference
      );

      await repository.saveTopUpDetails(customerUid, updatedDetails);
    }
  }

  /// Get all wallet transactions for a vendor
  Future<List<Map<String, dynamic>>> getCustomerWalletTransactions(
    String accountNumber,
  ) async {
    try {
      final txns = await monnify.getWalletTransactions(
        accountNumber: accountNumber,
      );
      return txns;
    } catch (e) {
      rethrow;
    }
  }

  /// Get vendor available wallet balance
  /// Returns only the availableBalance (int or double)
  Future<num> getCustomerWalletBalance(String accountNumber) async {
    try {
      final result = await monnify.getWalletBalance(
        accountNumber: accountNumber,
      );
      final balance = result['availableBalance'] as num;
      return balance;
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ Calls MonnifyFunctions to create a wallet.
  Future<Map<String, dynamic>> createWallet(Customer customer, String uid) async {
    final walletRef =
        'korra_${uid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

    return await monnify.createWallet(
      walletReference: walletRef,
      walletName: 'Korra_finance${'${customer.firstName}_${customer.lastName}'}',
      customerName: '${customer.firstName} ${customer.lastName}'.trim(),
      customerEmail: customer.email,
      bvn: customer.bvn,
      bvnDateOfBirth: _fmtDobIso(customer.dob!),
    );
  }

  /// Formats a DateTime object into a "YYYY-MM-DD" string.
  String _fmtDobIso(DateTime dob) {
    return "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
  }
}
