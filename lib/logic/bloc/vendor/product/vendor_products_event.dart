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

class VendorProductsAdd extends VendorProductsEvent {
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final List<File> images;

  const VendorProductsAdd({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.images,
  });

  @override
  List<Object?> get props => [name, description, price, stock, category, images];
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

class VendorProductsEdit extends VendorProductsEvent {
  final String productCode;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final List<String> existingImageUrls; // old images
  final List<File> newImages; // new ones if any 
  final ProductStatus status;

  const VendorProductsEdit({
    required this.productCode,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.existingImageUrls,
    required this.newImages,
    required this.status,
  });
}
