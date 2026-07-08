import '../../models/customer/korra_notification.dart';
import 'customer_repository.dart';

extension NotificationRepo on CustomerRepository {
  
  // Stream of Notifications (Ordered by newest)
  Stream<List<KorraNotification>> streamNotifications(String uid) {
    return firestore.collection('customers')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => KorraNotification.fromMap(doc.data(), doc.id)).toList());
  }

  // Stores this customer has muted (no notifications from them).
  Stream<List<String>> streamMutedStores(String uid) {
    return firestore.collection('customers')
        .doc(uid)
        .snapshots()
        .map((doc) => List<String>.from((doc.data()?['mutedStores'] ?? []) as List));
  }

  // Count unread — notifications from muted stores don't count.
  Stream<int> streamUnreadCount(String uid) {
    return firestore.collection('customers')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) return 0;
      final customerDoc = await firestore.collection('customers').doc(uid).get();
      final muted = List<String>.from((customerDoc.data()?['mutedStores'] ?? []) as List);
      if (muted.isEmpty) return snap.docs.length;
      return snap.docs.where((d) {
        final data = d.data();
        final metadata = data['metadata'];
        final vendorId = (data['vendorId'] ??
                (metadata is Map ? metadata['vendorId'] : null))
            ?.toString();
        return vendorId == null || !muted.contains(vendorId);
      }).length;
    });
  }

  // Mark as read
  Future<void> markNotificationRead(String uid, String notifId) async {
    await firestore.collection('customers')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }
  
  // Mark ALL as read (Engineering Polish)
  Future<void> markAllRead(String uid) async {
    final batch = firestore.batch();
    final unread = await firestore.collection('customers')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}