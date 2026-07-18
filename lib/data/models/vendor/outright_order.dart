// lib/data/models/vendor/outright_order.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum OutrightOrderStatus {
  awaitingPayment, // Web order placed, Monnify has not confirmed payment yet
  pending,         // New/Pending (payment confirmed)
  readyToDeliver,  // Awaiting Delivery/Handover
  delivered,       // Delivered/Completed
  cancelled        // Cancelled
}

class OutrightOrderItem {
  final String productId;
  final String title;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  /// Variant this line bought ("XL / Red"); null for products without
  /// variants (and all pre-variant orders).
  final String? variantLabel;

  OutrightOrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.variantLabel,
  });

  /// Title with the variant appended for list/summary rows.
  String get displayTitle =>
      variantLabel == null ? title : "$title ($variantLabel)";

  factory OutrightOrderItem.fromMap(Map<String, dynamic> map) {
    return OutrightOrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      variantLabel: map['variantLabel'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      if (variantLabel != null) 'variantLabel': variantLabel,
    };
  }
}

class OutrightOrder {
  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  // Guest web purchases (korra.com.ng): email is the only channel back to
  // the customer, and paymentStatus gates the merchant's books.
  final String customerEmail;
  final bool webPurchase;
  final String paymentStatus; // '', 'awaiting', 'paid', 'failed' (web only)

  /// Campaign tags active at the time of purchase, copied onto the order
  /// (snapshot, not a live reference — survives campaign expiry/deletion).
  /// Empty for orders placed with no active campaign.
  final List<String> promotions;
  final List<OutrightOrderItem> items;
  final double totalAmount;
  final String statusRaw;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final bool isMock;

  OutrightOrder({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress = '',
    this.customerEmail = '',
    this.webPurchase = false,
    this.paymentStatus = '',
    this.promotions = const [],
    required this.items,
    required this.totalAmount,
    required this.statusRaw,
    required this.createdAt,
    this.deliveredAt,
    this.cancelledAt,
    this.isMock = false,
  });

  // Status mapping. Unconfirmed web payments are their own status so they
  // get their own tab instead of polluting New.
  OutrightOrderStatus get status {
    if (webPurchase && paymentStatus == 'awaiting' && statusRaw == 'pending') {
      return OutrightOrderStatus.awaitingPayment;
    }
    switch (statusRaw) {
      case 'readyToDeliver':
        return OutrightOrderStatus.readyToDeliver;
      case 'delivered':
        return OutrightOrderStatus.delivered;
      case 'cancelled':
        return OutrightOrderStatus.cancelled;
      default:
        return OutrightOrderStatus.pending;
    }
  }

  // Helpers
  bool get isPending => status == OutrightOrderStatus.pending;

  /// Web order created but Monnify has not confirmed the payment yet: keep it
  /// visible in Orders, but off the merchant's transactions until it clears.
  bool get isAwaitingPayment => status == OutrightOrderStatus.awaitingPayment;
  bool get isReadyToDeliver => status == OutrightOrderStatus.readyToDeliver;
  bool get isDelivered => status == OutrightOrderStatus.delivered;
  bool get isCancelled => status == OutrightOrderStatus.cancelled;

  // Formatting
  String get totalText => "₦${(totalAmount).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";

  factory OutrightOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    
    return OutrightOrder(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Unknown Customer',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      webPurchase: data['webPurchase'] ?? false,
      paymentStatus: data['paymentStatus'] ?? '',
      promotions: List<String>.from(data['promotions'] ?? const []),
      items: itemsList.map((item) => OutrightOrderItem.fromMap(item as Map<String, dynamic>)).toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      statusRaw: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      isMock: data['isMock'] ?? false,
    );
  }
}
