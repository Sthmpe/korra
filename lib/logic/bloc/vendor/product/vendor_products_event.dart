import 'dart:io';

import 'package:equatable/equatable.dart';
import 'vendor_products_state.dart';

abstract class VendorProductsEvent extends Equatable {
  const VendorProductsEvent();
  @override
  List<Object?> get props => [];
}

class VendorProductsStarted extends VendorProductsEvent {
  const VendorProductsStarted();
}

class VendorProductsRefresh extends VendorProductsEvent {
  const VendorProductsRefresh();
}

class VendorProductsQueryChanged extends VendorProductsEvent {
  final String query;
  const VendorProductsQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class VendorProductsFilterChanged extends VendorProductsEvent {
  final ProductFilter filter;
  const VendorProductsFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class VendorProductsSharePressed extends VendorProductsEvent {
  final ProductItem product;
  const VendorProductsSharePressed(this.product);
  @override
  List<Object?> get props => [product];
}

class VendorProductsRestockPressed extends VendorProductsEvent {
  final String productId;
  const VendorProductsRestockPressed(this.productId);
  @override
  List<Object?> get props => [productId];
}

class VendorProductsRequested extends VendorProductsEvent {}

class VendorProductsLoadMore extends VendorProductsEvent {}

class VendorProductsUpdated extends VendorProductsEvent {
  final List<ProductItem> items;
  final Map<ProductFilter, int>? statusCounts;
  const VendorProductsUpdated(this.items, this.statusCounts);

  @override
  List<Object?> get props => [items, statusCounts];
}

class VendorProductsAdd extends VendorProductsEvent {
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  
  // 🔄 CHANGED: From List<String> to List<dynamic>
  // This allows us to pass File (Mobile) or XFile (Web) objects directly
  final List<dynamic> images; 
  
  final bool termsAccepted;
  final ProductModelType modelType;
  final String cancellationPolicy;
  final bool extensionsEnabled;
  final double? directDownPayment;
  final int duration;

  VendorProductsAdd({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.images, // ✅ Now accepts dynamic list
    required this.termsAccepted,
    required this.modelType,
    required this.cancellationPolicy,
    required this.extensionsEnabled,
    this.directDownPayment,
    required this.duration,
  });

  @override
  List<Object?> get props => [
        name, description, price, stock, category, images,
        termsAccepted, modelType, cancellationPolicy, extensionsEnabled,
        directDownPayment, duration,
      ];
}

class VendorProductsEdit extends VendorProductsEvent {
  final String productCode;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final List<String> existingImageUrls;
  
  // 🔄 CHANGED: From List<File> to List<dynamic>
  final List<dynamic> newImages; 

  final ProductStatus status;

  const VendorProductsEdit({
    required this.productCode,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.existingImageUrls,
    required this.newImages, // ✅ Now accepts dynamic list
    required this.status,
  });
  
  @override
  List<Object?> get props => [productCode, name, newImages, existingImageUrls];
}
