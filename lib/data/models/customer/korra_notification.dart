import 'package:cloud_firestore/cloud_firestore.dart';

class KorraNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'payment', 'reminder', 'system'

  KorraNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory KorraNotification.fromMap(Map<String, dynamic> map, String id) {
    return KorraNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'system',
    );
  }
}