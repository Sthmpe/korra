import '../../models/customer/korra_notification.dart';
import 'customer_repository.dart';

extension NotificationRepo on CustomerRepository {
  
  // Stream of Notifications (Ordered by newest)
  Stream<List<KorraNotification>> streamNotifications(String uid) {
    return db.collection('customer')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => KorraNotification.fromMap(doc.data(), doc.id)).toList());
  }

  // Count unread
  Stream<int> streamUnreadCount(String uid) {
    return db.collection('customer')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Mark as read
  Future<void> markNotificationRead(String uid, String notifId) async {
    await db.collection('customer')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }
  
  // Mark ALL as read (Engineering Polish)
  Future<void> markAllRead(String uid) async {
    final batch = db.batch();
    final unread = await db.collection('customer')
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