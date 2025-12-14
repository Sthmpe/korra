import 'package:equatable/equatable.dart';

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
  final String priceText; // formatted
  final int stock;
  final ProductStatus status;
  final List<String> imageUrl; // '' => fallback letter tile
  final DateTime createdAt;
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
    required this.priceText,
    required this.category,
    required this.stock,
    required this.status,
    required this.description,
    required this.createdAt,
    this.imageUrl = const [],
    this.modelType = ProductModelType.strict,
    this.cancellationPolicy = "50% Refund",
    this.baseDuration = "15 Days",
    this.noticePeriod = "1 Day",
    this.totalMaxTime = "16 Days",
    this.extensionsEnabled = false,
    this.directDownPayment,
  });

  bool get shareable => status == ProductStatus.approved && stock > 0;

  @override
  List<Object?> get props => [id, name, priceText, stock, status, imageUrl, code, description, category, createdAt, modelType, cancellationPolicy, baseDuration, noticePeriod, totalMaxTime, extensionsEnabled, directDownPayment];
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
