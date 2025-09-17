import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/vendor/payout/pin_model.dart';
import 'vendor_repository.dart';

extension PinRepository on VendorRepository {
  /// Hash PIN with bcrypt (via Supabase Edge Function or local)
  Future<String> hashPin(String pin) async {
    try {
      final response = await fx.invoke('hash-pin', body: {'pin': pin});
      if (response.data != null && response.data['hash'] != null) {
        return response.data['hash'] as String;
      }
      throw Exception('Failed to hash pin');
    } catch (e) {
      debugPrint("Error hashing pin: $e");
      rethrow;
    }
  }

  /// Verify PIN against stored hash
  Future<bool> verifyPin(String pin, String storedHash) async {
    try {
      final response = await fx.invoke('verify-pin', body: {
        'pin': pin,
        'storedHash': storedHash,
      });
      if (response.data != null && response.data['valid'] != null) {
        return response.data['valid'] as bool;
      }
      throw Exception('Failed to verify pin');
    } catch (e) {
      debugPrint("Error verifying pin: $e");
      rethrow;
    }
  }

  /// Save hashed PIN to Firestore
  Future<void> savePin(PinModel pin) async {
    await firestore.collection('userPins').doc(pin.userId).set(
          pin.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Get stored PinModel
  Future<PinModel?> getPin(String userId) async {
    final doc = await firestore.collection('userPins').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PinModel.fromMap(doc.data()!);
  }
}
