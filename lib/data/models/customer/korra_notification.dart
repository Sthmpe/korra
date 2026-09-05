import 'package:cloud_firestore/cloud_firestore.dart';

class KorraNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'payment', 'reminder', 'system'

  /// Store the notification came from (campaign/store fan-out). Null for
  /// system notifications — those are never filtered by store mutes.
  final String? vendorId;

  /// Campaign image (set by campaign-broadcast's `metadata.image`). Null for
  /// non-campaign notifications or campaigns without a photo.
  final String? imageUrl;

  KorraNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.vendorId,
    this.imageUrl,
  });

  factory KorraNotification.fromMap(Map<String, dynamic> map, String id) {
    final metadata = map['metadata'];
    final image = metadata is Map ? metadata['image']?.toString() : null;
    return KorraNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'system',
      vendorId: (map['vendorId'] ??
              (metadata is Map ? metadata['vendorId'] : null))
          ?.toString(),
      imageUrl: (image != null && image.isNotEmpty) ? image : null,
    );
  }
}
