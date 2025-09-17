import 'package:korra/data/repository/vendors/payout_repository.dart';
import '../../models/vendor/payout/payout_details.dart';
import '../../models/vendor/vendor_model.dart';
import 'vendor_repository.dart';

extension WalletRepository on VendorRepository {
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

  
  Future<void> updateWithdrawableBalance(
    String vendorUid,
    String walletAccountNumber,
  ) async {
    final data = await monnify.getWalletBalance(
      accountNumber: walletAccountNumber,
    );
    final balance = data['availableBalance'] as num? ?? 0;

    final repository = VendorRepository();
    final currentDetails = await repository.getPayoutDetails(vendorUid);

    if (currentDetails != null) {
      // Update only the withdrawable balance, keep other details
      final updatedDetails = PayoutDetails(
        withdrawableBalance: balance,
        walletAccountNumber: currentDetails.walletAccountNumber,
        walletAccountName: currentDetails.walletAccountName,
        walletAccountReference: currentDetails.walletAccountReference,
        bankCode: currentDetails.bankCode,
        bankAccountNumber: currentDetails.bankAccountNumber,
        bankAccountName: currentDetails.bankAccountName,
        bankName: currentDetails.bankName,
      );

      await repository.savePayoutDetails(vendorUid, updatedDetails);
    }
  }

  /// Get all wallet transactions for a vendor
  Future<List<Map<String, dynamic>>> getVendorWalletTransactions(
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
  Future<num> getVendorWalletBalance(String accountNumber) async {
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
  Future<Map<String, dynamic>> createWallet(Vendor vendor, String uid) async {
    final walletRef =
        'korra_${uid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

    return await monnify.createWallet(
      walletReference: walletRef,
      walletName: vendor.storeName,
      customerName: '${vendor.ownerFirst} ${vendor.ownerLast}'.trim(),
      customerEmail: vendor.email,
      bvn: vendor.bvn,
      bvnDateOfBirth: _fmtDobIso(vendor.dob!),
    );
  }

  /// Formats a DateTime object into a "YYYY-MM-DD" string.
  String _fmtDobIso(DateTime dob) {
    return "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
  }
}
