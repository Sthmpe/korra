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

class VendorProductsCreatePressed extends VendorProductsEvent {
  const VendorProductsCreatePressed();
}

class VendorProductsSharePressed extends VendorProductsEvent {
  final String productId;
  const VendorProductsSharePressed(this.productId);
  @override
  List<Object?> get props => [productId];
}

class VendorProductsEditPressed extends VendorProductsEvent {
  final String productId;
  const VendorProductsEditPressed(this.productId);
  @override
  List<Object?> get props => [productId];
}

class VendorProductsRestockPressed extends VendorProductsEvent {
  final String productId;
  const VendorProductsRestockPressed(this.productId);
  @override
  List<Object?> get props => [productId];
}
