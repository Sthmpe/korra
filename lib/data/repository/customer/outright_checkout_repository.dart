import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/utils/korra_exception.dart';
import '../../models/customer/payment_receipt_data.dart';
import 'customer_repository.dart';

extension OutrightCheckout on CustomerRepository {
  /// Pays IN FULL for a cart of products from one store.
  ///
  /// Calls the `outright-checkout` edge function (same Double-Lock security as
  /// plan-manager). The server owns all money math — it re-reads product prices,
  /// applies the merchant's `absorbOutrightFee` flag, the 3.5%/₦7,500 fee and
  /// the rounding rules, then records the order + receipt. We only send the
  /// vendor id and item ids/quantities; prices are never trusted from the client.
  Future<PaymentReceiptData> checkoutOutright({
    required String vendorId,
    required List<Map<String, dynamic>> items, // [{productId, quantity}]
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw "You must be logged in.";

      final idToken = await user.getIdToken(true);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final signature = hmacSha256.convert(utf8.encode(timestamp)).toString();

      debugPrint("🔒 Calling outright-checkout with Double Lock...");

      final response = await fx.invoke(
        'outright-checkout',
        headers: {
          'firebase-token': 'Bearer $idToken',
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          "vendorId": vendorId,
          "items": items,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      if (data['status'] == 'ERROR') {
        throw KorraException(data['error'] ?? "Checkout failed. Please try again.");
      }

      // Fail-safe parse: if the receipt can't be read but the order went
      // through, still return success — the money already moved.
      try {
        if (data['receiptData'] == null) throw "No receipt data returned";
        return PaymentReceiptData.fromJson(Map<String, dynamic>.from(data['receiptData']));
      } catch (parseError) {
        debugPrint("⚠️ Outright receipt parse error: $parseError");
        return PaymentReceiptData.fromPartial(
          amount: 0,
          date: DateTime.now(),
          title: "Purchase Successful",
          reference: data['orderId']?.toString() ?? "REF-${DateTime.now().millisecondsSinceEpoch}",
          status: "SUCCESSFUL",
        );
      }
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw KorraException(details['error']);
      }
      throw KorraException(
        "Checkout failed. Please try again.",
        technicalDetails: e.toString(),
      );
    } catch (e) {
      if (e is KorraException) rethrow;
      throw KorraException("Checkout failed. Please try again.");
    }
  }
}
