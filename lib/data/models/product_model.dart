import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

// Ensure this import points to where ProductModelType and ProductStatus are defined
import '../../logic/bloc/vendor/product/vendor_products_state.dart'; 

class Product {
  final String id;
  final String vendorId;
  final String storeName;
  final String code;
  final String name;
  final String description;
  final double price;
  final int initialStock; 
  final int availableStock;
  final List<String> images;
  final String category;
  final ProductStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ✅ SMART CONTRACT FIELDS
  final ProductModelType modelType;       // "strict" or "direct"
  final String cancellationPolicy;        // e.g. "50% Refund"
  final bool extensionsEnabled;           // true/false
  final double? directDownPayment;        // Only for Direct model

  // ✅ TIMELINE FIELDS (Pre-calculated)
  final String baseDuration;  // e.g. "15 Days"
  final String noticePeriod;  // e.g. "1 Day"
  final String totalMaxTime;  // e.g. "16 Days"

  Product({
    required this.id,
    required this.vendorId,
    required this.storeName,
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    required this.initialStock,
    required this.availableStock,
    required this.images,
    required this.category,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    // New Fields
    required this.modelType,
    required this.cancellationPolicy,
    required this.extensionsEnabled,
    this.directDownPayment,
    required this.baseDuration,
    required this.noticePeriod,
    required this.totalMaxTime,
  });

  /// Create new product as pending
  factory Product.create({
    required String vendorId,
    required String storeName,
    required String name,
    required String description,
    required double price,
    required int stock,
    required List<String> images,
    required String category,
    required ProductStatus status,
    String? rejectionReason,
    // New Params
    required ProductModelType modelType,
    required String cancellationPolicy,
    required bool extensionsEnabled,
    double? directDownPayment,
    required String baseDuration,
    required String noticePeriod,
    required String totalMaxTime,
  }) {
    final now = DateTime.now();
    return Product(
      id: "",
      vendorId: vendorId,
      code: _generateProductCode(vendorId),
      storeName: storeName,
      name: name,
      description: description,
      price: price,
      initialStock: stock,
      availableStock: stock,
      images: images,
      category: category,
      status: status,
      rejectionReason: '',
      createdAt: now,
      updatedAt: now,
      // Set New Fields
      modelType: modelType,
      cancellationPolicy: cancellationPolicy,
      extensionsEnabled: extensionsEnabled,
      directDownPayment: directDownPayment,
      baseDuration: baseDuration,
      noticePeriod: noticePeriod,
      totalMaxTime: totalMaxTime,
    );
  }

  Product copyWith({
    String? id,
    String? vendorId,
    String? storeName,
    String? code,
    String? name,
    String? description,
    double? price,
    int? initialStock,
    int? availableStock,
    List<String>? images,
    String? category,
    ProductStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProductModelType? modelType,
    String? cancellationPolicy,
    bool? extensionsEnabled,
    double? directDownPayment,
    String? baseDuration,
    String? noticePeriod,
    String? totalMaxTime,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      storeName: storeName ?? this.storeName,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      initialStock: initialStock ?? this.initialStock,
      availableStock: availableStock ?? this.availableStock,
      images: images ?? this.images,
      category: category ?? this.category,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modelType: modelType ?? this.modelType,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      extensionsEnabled: extensionsEnabled ?? this.extensionsEnabled,
      directDownPayment: directDownPayment ?? this.directDownPayment,
      baseDuration: baseDuration ?? this.baseDuration,
      noticePeriod: noticePeriod ?? this.noticePeriod,
      totalMaxTime: totalMaxTime ?? this.totalMaxTime,
    );
  }

  static String _generateProductCode(String vendorId) {
    final vendorPrefix = vendorId.substring(0, 4).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final input = vendorId + timestamp;
    final hash = sha256.convert(utf8.encode(input)).toString();
    final shortHash = hash.substring(0, 7);
    return "K-$vendorPrefix-$shortHash";
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      vendorId: map['vendorId'] ?? '',
      storeName: map['storeName'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      initialStock: (map['initialStock'] ?? 0).toInt(),
      availableStock: (map['availableStock'] ?? 0).toInt(),
      images: List<String>.from(map['images'] ?? []),
      category: map['category'] ?? '',
      status: ProductStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'pending'),
        orElse: () => ProductStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // ✅ Map New Fields
      modelType: ProductModelType.values.firstWhere(
        (m) => m.name == (map['modelType'] ?? 'strict'),
        orElse: () => ProductModelType.strict,
      ),
      cancellationPolicy: map['cancellationPolicy'] ?? '50% Refund',
      extensionsEnabled: map['extensionsEnabled'] ?? false,
      directDownPayment: (map['directDownPayment'] as num?)?.toDouble(),
      baseDuration: map['baseDuration'] ?? '15 Days',
      noticePeriod: map['noticePeriod'] ?? '1 Day',
      totalMaxTime: map['totalMaxTime'] ?? '16 Days',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'storeName': storeName,
      'code': code,
      'name': name,
      'description': description,
      'price': price,
      'initialStock': initialStock,
      'availableStock': availableStock,
      'images': images,
      'category': category,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // ✅ Save New Fields
      'modelType': modelType.name,
      'cancellationPolicy': cancellationPolicy,
      'extensionsEnabled': extensionsEnabled,
      'directDownPayment': directDownPayment,
      'baseDuration': baseDuration,
      'noticePeriod': noticePeriod,
      'totalMaxTime': totalMaxTime,
    };
  }
}