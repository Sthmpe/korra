import '../../../config/utils/korra_exception.dart';
import 'vendor_repository.dart';

extension PinRepository on VendorRepository {
  
  Future<void> setTransactionPin(String uid, String pin) async {
    try {
      final response = await fx.invoke(
        'vendor-transaction-ops',
        body: {
          'type': 'create_pin',
          'uid': uid,
          'pin': pin, 
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? "Failed to set PIN");
      }
    } catch (e) {
      // Reuse the logic or a simple translator
      final msg = e.toString().toLowerCase();
      
      if (msg.contains('socketexception')) {
        throw KorraException(
          "Connection failed. Could not save your PIN.",
          technicalDetails: "Network Error",
        );
      }
      
      throw KorraException(
        "We couldn't verify your PIN securely. Please try again.",
        technicalDetails: e.toString(),
      );
    }
  }
}