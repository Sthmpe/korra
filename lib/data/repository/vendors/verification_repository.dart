import 'vendor_repository.dart';

extension VerificationRepository on VendorRepository {
  /// Verify NIN through Monnify
  Future<void> verifyNin(String nin) async {
    try {
      await monnify.verifyNin(nin);
      //debugPrint("NIN verified successfully for $nin");
      return;
    } catch (e) {
      // debugPrint("NIN verification failed: $e");
      throw Exception("NIN verification failed: $e");
    }
  }

  /// ✅ Verify BVN through Monnify
  Future<void> verifyBvn({
    required String bvn,
    required String name,
    required String dateOfBirthIso,
    required String mobileNo,
  }) async {
    try {
      final result = await monnify.verifyBvn(
        bvn: bvn,
        name: name,
        dateOfBirthIso: dateOfBirthIso,
        mobileNo: mobileNo,
      );

      // Business rule: must not be NO_MATCH
      final nameMatch = result['nameMatch'] as String? ?? "NO_MATCH";
      final mobileMatch = result['mobileMatch'] as String? ?? "NO_MATCH";

      if (nameMatch == "NO_MATCH" || mobileMatch == "NO_MATCH") {
        throw Exception(
          "BVN verification failed: Name or Mobile did not match",
        );
      }

      //debugPrint("✅ BVN verified successfully for $name");
    } catch (e) {
      // debugPrint("❌ BVN verification failed: $e");
      throw Exception("BVN verification failed: $e");
    }
  }
}