// lib/data/models/vendor/campaign_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  final String id;
  final String vendorId;
  final List<String> productIds;
  final List<String> productTitles;
  final String tag;
  final String title;
  final String caption;
  final String imageUrl;
  final DateTime sentAt;
  final int openCount;
  final bool isMock;

  // Discount options
  final String discountType; // 'none' | 'percentage' | 'amount'
  final double discountValue;

  // Deal countdown timer — independent of the tag. When set, customers see
  // a live countdown between [dealStartAt] and [dealEndAt].
  final DateTime? dealStartAt;
  final DateTime? dealEndAt;

  Campaign({
    required this.id,
    required this.vendorId,
    required this.productIds,
    required this.productTitles,
    required this.tag,
    required this.title,
    required this.caption,
    required this.imageUrl,
    required this.sentAt,
    required this.openCount,
    this.isMock = false,
    this.discountType = 'none',
    this.discountValue = 0.0,
    this.dealStartAt,
    this.dealEndAt,
  });

  bool get isActive {
    // Timed deals live until their merchant-chosen end time. Untimed
    // campaigns no longer auto-expire after 24h — the merchant now controls
    // their lifecycle explicitly by deleting them (see CampaignsRepository
    // deleteCampaign/deleteCampaigns).
    if (dealEndAt != null) return DateTime.now().isBefore(dealEndAt!);
    return true;
  }

  bool get hasTimer => dealStartAt != null && dealEndAt != null;

  /// Timer is set and the deal window is currently open.
  bool get timerRunning {
    if (!hasTimer) return false;
    final now = DateTime.now();
    return now.isAfter(dealStartAt!) && now.isBefore(dealEndAt!);
  }

  /// Timer is set but the deal hasn't opened yet.
  bool get timerUpcoming => hasTimer && DateTime.now().isBefore(dealStartAt!);

  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Support migration from single productId/productTitle
    final List<String> pIds = data['productIds'] != null
        ? List<String>.from(data['productIds'])
        : (data['productId'] != null ? [data['productId'].toString()] : []);
        
    final List<String> pTitles = data['productTitles'] != null
        ? List<String>.from(data['productTitles'])
        : (data['productTitle'] != null ? [data['productTitle'].toString()] : []);

    return Campaign(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      productIds: pIds,
      productTitles: pTitles,
      tag: data['tag'] ?? '',
      title: data['title'] ?? '',
      caption: data['caption'] ?? data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      openCount: (data['openCount'] ?? 0).toInt(),
      isMock: data['isMock'] ?? false,
      discountType: data['discountType'] ?? 'none',
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      dealStartAt: (data['dealStartAt'] as Timestamp?)?.toDate(),
      dealEndAt: (data['dealEndAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'productIds': productIds,
      'productTitles': productTitles,
      'tag': tag,
      'title': title,
      'caption': caption,
      'imageUrl': imageUrl,
      'sentAt': Timestamp.fromDate(sentAt),
      'openCount': openCount,
      'isMock': isMock,
      'discountType': discountType,
      'discountValue': discountValue,
      if (dealStartAt != null) 'dealStartAt': Timestamp.fromDate(dealStartAt!),
      if (dealEndAt != null) 'dealEndAt': Timestamp.fromDate(dealEndAt!),
    };
  }
}
