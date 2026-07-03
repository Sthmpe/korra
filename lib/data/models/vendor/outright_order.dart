// lib/data/models/vendor/outright_order.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum OutrightOrderStatus {
  pending,         // New/Pending
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

  OutrightOrderItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  factory OutrightOrderItem.fromMap(Map<String, dynamic> map) {
    return OutrightOrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class OutrightOrder {
  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String customerPhone;
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
    required this.items,
    required this.totalAmount,
    required this.statusRaw,
    required this.createdAt,
    this.deliveredAt,
    this.cancelledAt,
    this.isMock = false,
  });

  // Status mapping
  OutrightOrderStatus get status {
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
