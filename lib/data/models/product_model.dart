import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../logic/bloc/vendor/product/vendor_products_state.dart';

class Product {
  final String id;
  final String vendorId;
  final String code;
  final String name;
  final String description;
  final double price;
  final int initialStock; // set when created
  final int availableStock;
  final List<String> images;
  final String category;
  final ProductStatus status; // NEW
  final String? rejectionReason; // AI / Supabase message
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.vendorId,
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
  });

  /// Create new product as pending
  factory Product.create({
    required String vendorId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required List<String> images,
    required String category,
    required ProductStatus status,
    String? rejectionReason,
  }) {
    final now = DateTime.now();
    return Product(
      id: "",
      vendorId: vendorId,
      code: _generateProductCode(vendorId),
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
    );
  }

  Product copyWith({
    String? id,
    String? vendorId,
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
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
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
    );
  }

  static String _generateProductCode(String vendorId) {
    final vendorPrefix = vendorId.substring(0, 4).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final input = vendorId + timestamp;
    final hash = sha256.convert(utf8.encode(input)).toString();
    final shortHash = hash.substring(0, 7);
    return "korra-$vendorPrefix-$shortHash";
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      vendorId: map['vendorId'] ?? '',
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
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
    };
  }
}
