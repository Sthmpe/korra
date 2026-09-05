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

  /// Unique opens: one per customer per calendar day (deduped server-side in
  /// record-visit via campaigns/{id}/opens markers). In-app opens only — web
  /// page loads are tracked separately as Web Activity, never here.
  final int openCount;

  /// Orders placed while this campaign's tag was active on the product,
  /// attributed by campaign ID at checkout (see promotionCampaignIds).
  final int purchases;

  /// Opens per day: { 'yyyy-MM-dd': n } — feeds the analytics breakdown.
  final Map<String, int> dailyOpens;

  /// Soft delete: merchants "delete" a campaign but the record survives as
  /// history. Archived campaigns are inactive everywhere and don't count
  /// against the 3-active limit.
  final bool archived;

  /// When the campaign ended: manual deletion timestamp (archived) — for
  /// expired countdowns the end date is dealEndAt instead.
  final DateTime? endedAt;
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
    this.purchases = 0,
    this.dailyOpens = const {},
    this.archived = false,
    this.endedAt,
    this.isMock = false,
    this.discountType = 'none',
    this.discountValue = 0.0,
    this.dealStartAt,
    this.dealEndAt,
  });

  bool get isActive {
    // Archived (soft-deleted) campaigns are over, full stop.
    if (archived) return false;
    // Timed deals live until their merchant-chosen end time. Untimed
    // campaigns no longer auto-expire after 24h — the merchant now controls
    // their lifecycle explicitly by deleting them (see CampaignsRepository
    // deleteCampaign/deleteCampaigns).
    if (dealEndAt != null) return DateTime.now().isBefore(dealEndAt!);
    return true;
  }

  /// History entries: manually ended (archived) or a countdown that ran out.
  bool get isPast => !isActive;

  /// The end date shown in history: manual deletion time, else the
  /// countdown's auto-expiry time.
  DateTime? get endDate => endedAt ?? dealEndAt;

  /// purchases ÷ unique opens, 0..1. Zero opens → zero (no divide-by-zero).
  double get conversionRate => openCount > 0 ? purchases / openCount : 0;

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
      purchases: (data['purchases'] ?? 0).toInt(),
      dailyOpens: Map<String, dynamic>.from(data['dailyOpens'] ?? const {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      archived: data['archived'] ?? false,
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
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
      'purchases': purchases,
      'archived': archived,
      'isMock': isMock,
      'discountType': discountType,
      'discountValue': discountValue,
      if (dealStartAt != null) 'dealStartAt': Timestamp.fromDate(dealStartAt!),
      if (dealEndAt != null) 'dealEndAt': Timestamp.fromDate(dealEndAt!),
    };
  }
}
