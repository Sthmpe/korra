import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum ProductModelType { strict, direct }
enum ProductStatus { approved, pending, rejected, outOfStock }
enum ProductFilter { all, approved, pending, outOfStock, rejected }
enum ProductFlow { create, edit, idle}

class ProductItem extends Equatable {
  final String id;
  final String code;
  final String name;
  final String description;
  final String category;
  
  final double price; // ✅ Added raw double for math/logic
  final String priceText; // Formatted string for display
  
  final int stock;
  final ProductStatus status;
  final List<String> imageUrl; 
  final DateTime createdAt;
  
  // Smart Contract / Timeline Fields
  final ProductModelType modelType;
  final String cancellationPolicy;
  final String baseDuration;
  final String noticePeriod;
  final String totalMaxTime;
  final bool extensionsEnabled;
  final double? directDownPayment;

  const ProductItem({
    required this.id,
    required this.name,
    required this.code,
    required this.price, // ✅ Required
    required this.priceText,
    required this.category,
    required this.stock,
    required this.status,
    required this.description,
    required this.createdAt,
    this.imageUrl = const [],
    this.modelType = ProductModelType.strict,
    this.cancellationPolicy = "Store Credit", // ✅ Updated Default
    this.baseDuration = "14 Days",
    this.noticePeriod = "3 Days",
    this.totalMaxTime = "17 Days",
    this.extensionsEnabled = false,
    this.directDownPayment,
  });

  bool get shareable => status == ProductStatus.approved && stock > 0;

  // ✅ THIS IS THE MISSING PIECE
  // It maps Firestore Data (Map) -> ProductItem (Class)
  factory ProductItem.fromJson(Map<String, dynamic> json, String id) {
    // 1. Safe Price Parsing (Handle int/double from DB)
    final rawPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    
    // 2. Format Price Text immediately
    final formattedPrice = NumberFormat.currency(
      symbol: '₦', 
      decimalDigits: 0
    ).format(rawPrice);

    // 3. Parse Status String to Enum
    ProductStatus parseStatus(String? val) {
      return ProductStatus.values.firstWhere(
        (e) => e.name == val, 
        orElse: () => ProductStatus.pending
      );
    }

    // 4. Parse Model Type
    ProductModelType parseModel(String? val) {
      return val == 'direct' ? ProductModelType.direct : ProductModelType.strict;
    }

    // 5. Parse Date
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      // Handle Firestore Timestamp or standard Date
      if (val.toString().contains('Timestamp')) {
        return (val as dynamic).toDate();
      }
      return DateTime.now(); 
    }

    return ProductItem(
      id: id,
      code: json['code'] ?? id,
      name: json['name'] ?? 'Unknown Product',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      
      price: rawPrice,
      priceText: formattedPrice,
      
      stock: json['availableStock'] ?? 0, // Ensure this matches DB field name
      status: parseStatus(json['status']),
      imageUrl: List<String>.from(json['images'] ?? []),
      createdAt: parseDate(json['createdAt']),
      
      // ✅ Map new Timeline Fields
      modelType: parseModel(json['modelType']),
      cancellationPolicy: json['cancellationPolicy'] ?? 'Store Credit',
      baseDuration: json['baseDuration'] ?? '14 Days',
      noticePeriod: json['noticePeriod'] ?? '3 Days',
      totalMaxTime: json['totalMaxTime'] ?? '17 Days',
      extensionsEnabled: json['extensionsEnabled'] ?? false,
      directDownPayment: (json['directDownPayment'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id, name, price, priceText, stock, status, imageUrl, code, 
    description, category, createdAt, modelType, cancellationPolicy, 
    baseDuration, noticePeriod, totalMaxTime, extensionsEnabled, directDownPayment
  ];
}

class VendorProductsState extends Equatable {
  final String query;
  final ProductFilter filter;
  final List<ProductItem> items;
  final ProductFlow? flow;
  final bool? isSubmitting;
  final bool? success;
  final String? errorMessage;
  final Map<ProductFilter, int> statusCounts;
  final double availableLimit;

  const VendorProductsState({
    required this.query,
    required this.filter,
    required this.items,
    this.flow,
    this.isSubmitting,
    this.success,
    this.errorMessage,
    this.statusCounts = const {},
    this.availableLimit = 0.0,
  });

  List<ProductItem> get visibleItems {
    final q = query.trim().toLowerCase();
    return items.where((p) {
      final passQ = q.isEmpty || p.name.toLowerCase().contains(q);
      final passF = switch (filter) {
        ProductFilter.all => true,
        ProductFilter.approved => p.status == ProductStatus.approved,
        ProductFilter.pending => p.status == ProductStatus.pending,
        ProductFilter.outOfStock => p.status == ProductStatus.outOfStock,
        ProductFilter.rejected => p.status == ProductStatus.rejected,
      };
      return passQ && passF;
    }).toList();
  }

  String get totalCountLabel {
    if (filter == ProductFilter.all) {
      return "All (${items.length})";
    } else {
      final filteredCount = items.where((p) {
        if (filter == ProductFilter.approved) {
          return p.status == ProductStatus.approved;
        } else if (filter == ProductFilter.pending) {
          return p.status == ProductStatus.pending;
        } else if (filter == ProductFilter.rejected) {
          return p.status == ProductStatus.rejected;
        } else if (filter == ProductFilter.outOfStock) {
          return p.status == ProductStatus.outOfStock;
        }
        return true;
      }).length;

      final filterName = filter.name[0].toUpperCase() + filter.name.substring(1);
      return "$filterName ($filteredCount)";
    }
  }

  VendorProductsState copyWith({
    String? query,
    ProductFilter? filter,
    List<ProductItem>? items, 
    bool? success,
    bool? isSubmitting,
    String? errorMessage,
    Map<ProductFilter, int>? statusCounts,
    double? availableLimit,
  }) {
    return VendorProductsState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      items: items ?? this.items,
      flow: flow ?? this.flow,
      success: success ?? this.success,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCounts: statusCounts ?? this.statusCounts,
      availableLimit: availableLimit ?? this.availableLimit,
    );
  }

  factory VendorProductsState.initial() => VendorProductsState(
    isSubmitting: false,
    success: false,
    errorMessage: null,
    query: '',
    filter: ProductFilter.all,
    items: [],
    statusCounts: {}
  );

  @override
  List<Object?> get props => [query, filter, items, isSubmitting, success, errorMessage, flow, statusCounts, availableLimit];
}
