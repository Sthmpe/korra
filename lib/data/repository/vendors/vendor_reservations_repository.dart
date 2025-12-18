import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor/vendor_reservation.dart';

class VendorReservationsRepository {
  final String vendorId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  VendorReservationsRepository({required this.vendorId});

  Future<List<VendorReservation>> fetchAll() async {
    try {
      final snap = await _db
          .collection('plans')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      // ✅ FIX: Use the factory. This maps fields correctly automatically.
      return snap.docs.map((doc) => VendorReservation.fromFirestore(doc)).toList();
      
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}