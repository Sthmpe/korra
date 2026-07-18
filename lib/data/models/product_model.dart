import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

// Ensure this import points to where ProductModelType and ProductStatus are defined
import '../../logic/bloc/vendor/product/vendor_products_state.dart'; 

/// One purchasable variant of a product: a free-text label the merchant
/// defines ("XL", "40", "XL / Red", "Ankara 500ml") with its own stock.
/// Flat by design — no attribute matrix; combinations live in the label.
class ProductVariant {
  final String label;
  final int stock;

  const ProductVariant({required this.label, required this.stock});

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
        label: (map['label'] ?? '').toString(),
        stock: (map['stock'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {'label': label, 'stock': stock};

  ProductVariant copyWith({String? label, int? stock}) =>
      ProductVariant(label: label ?? this.label, stock: stock ?? this.stock);
}

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
  final bool allowReservation;            // Whether installments are allowed (default to true)

  // ✅ TIMELINE FIELDS (Pre-calculated)
  final String baseDuration;  // e.g. "15 Days"
  final String noticePeriod;  // e.g. "1 Day"
  final String totalMaxTime;  // e.g. "16 Days"

  // ✅ CAMPAIGNS & DISCOUNTS & FEATURING FIELDS
  final String? campaignTag;
  final double? discountedPrice;
  final bool isFeatured;

  /// When the campaign that applied [campaignTag]/[discountedPrice] ends.
  /// Set only for TIMED campaigns; null means the campaign is untimed (runs
  /// until the merchant deletes it). Once this passes, the tag and discount
  /// are treated as expired everywhere — see [promoActive] — with no
  /// dependency on any server/merchant sweep to clean the fields.
  final DateTime? campaignEndsAt;

  /// One campaign, one tag per product: true while this product's campaign
  /// tag/discount should still show. Untimed campaigns are active until
  /// deleted; timed ones lapse at [campaignEndsAt].
  bool get promoActive {
    final t = campaignTag;
    if (t == null || t.trim().isEmpty) return false;
    final ends = campaignEndsAt;
    return ends == null || DateTime.now().isBefore(ends);
  }

  /// The tag to display, or null once the campaign has lapsed.
  String? get activeCampaignTag => promoActive ? campaignTag : null;

  /// The discounted price to charge/show, or null once the campaign has
  /// lapsed (reverts to full [price]).
  double? get activeDiscountedPrice => promoActive ? discountedPrice : null;

  // ✅ VARIANTS (optional, backward compatible)
  /// Flat labeled variants with per-variant stock. Empty = classic product
  /// with a single flat [availableStock]. When non-empty, [availableStock]
  /// is ALWAYS the recalculated sum of variant stocks (enforced on every
  /// write path — merchant editor, checkout, plan-manager, crons).
  final List<ProductVariant> variants;

  bool get hasVariants => variants.isNotEmpty;

  /// Stock of one variant by label (null when the product has no variants
  /// or the label doesn't exist).
  int? variantStock(String label) {
    for (final v in variants) {
      if (v.label == label) return v.stock;
    }
    return null;
  }

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
    required this.allowReservation,
    this.campaignTag,
    this.discountedPrice,
    this.isFeatured = false,
    this.campaignEndsAt,
    this.variants = const [],
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
    required bool allowReservation,
    String? campaignTag,
    double? discountedPrice,
    bool isFeatured = false,
    DateTime? campaignEndsAt,
    List<ProductVariant> variants = const [],
  }) {
    final now = DateTime.now();
    // With variants, the flat stock param is ignored in favor of the sum.
    final variantTotal =
        variants.fold<int>(0, (acc, v) => acc + (v.stock < 0 ? 0 : v.stock));
    final effectiveStock = variants.isNotEmpty ? variantTotal : stock;
    return Product(
      id: "",
      vendorId: vendorId,
      code: _generateProductCode(vendorId),
      storeName: storeName,
      name: name,
      description: description,
      price: price,
      initialStock: effectiveStock,
      availableStock: effectiveStock,
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
      allowReservation: allowReservation,
      campaignTag: campaignTag,
      discountedPrice: discountedPrice,
      isFeatured: isFeatured,
      campaignEndsAt: campaignEndsAt,
      variants: variants,
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
    bool? allowReservation,
    String? campaignTag,
    double? discountedPrice,
    bool? isFeatured,
    DateTime? campaignEndsAt,
    List<ProductVariant>? variants,
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
      allowReservation: allowReservation ?? this.allowReservation,
      campaignTag: campaignTag ?? this.campaignTag,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      isFeatured: isFeatured ?? this.isFeatured,
      campaignEndsAt: campaignEndsAt ?? this.campaignEndsAt,
      variants: variants ?? this.variants,
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
      allowReservation: map['allowReservation'] ?? true, // Default to true for backward compatibility
      campaignTag: map['campaignTag'],
      discountedPrice: (map['discountedPrice'] as num?)?.toDouble(),
      isFeatured: map['isFeatured'] ?? false,
      campaignEndsAt: (map['campaignEndsAt'] as Timestamp?)?.toDate(),
      variants: (map['variants'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ProductVariant.fromMap)
              .toList() ??
          const [],
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
      'allowReservation': allowReservation,
      'isFeatured': isFeatured,
      if (campaignTag != null) 'campaignTag': campaignTag,
      if (discountedPrice != null) 'discountedPrice': discountedPrice,
      if (campaignEndsAt != null) 'campaignEndsAt': campaignEndsAt,
      if (variants.isNotEmpty)
        'variants': variants.map((v) => v.toMap()).toList(),
    };
  }
}