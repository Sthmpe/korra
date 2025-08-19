import 'package:equatable/equatable.dart';

enum ProductStatus { approved, pending, rejected, hidden, outOfStock }
enum ProductFilter { all, approved, pending, outOfStock, hidden }

class ProductItem extends Equatable {
  final String id;
  final String name;
  final String priceText; // formatted
  final int stock;
  final ProductStatus status;
  final String imageUrl; // '' => fallback letter tile

  const ProductItem({
    required this.id,
    required this.name,
    required this.priceText,
    required this.stock,
    required this.status,
    this.imageUrl = '',
  });

  bool get shareable => status == ProductStatus.approved && stock > 0;

  @override
  List<Object?> get props => [id, name, priceText, stock, status, imageUrl];
}

class VendorProductsState extends Equatable {
  final String query;
  final ProductFilter filter;
  final List<ProductItem> items;

  const VendorProductsState({
    required this.query,
    required this.filter,
    required this.items,
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
        ProductFilter.hidden => p.status == ProductStatus.hidden,
      };
      return passQ && passF;
    }).toList();
  }

  String get totalCountLabel => '${items.length} total';

  VendorProductsState copyWith({
    String? query,
    ProductFilter? filter,
    List<ProductItem>? items,
  }) {
    return VendorProductsState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      items: items ?? this.items,
    );
  }

  factory VendorProductsState.mock() => VendorProductsState(
        query: '',
        filter: ProductFilter.all,
        items: const [
          ProductItem(
            id: 'p1',
            name: 'Bose 700',
            priceText: '₦420,000',
            stock: 8,
            status: ProductStatus.approved,
          ),
          ProductItem(
            id: 'p2',
            name: 'AirPods Pro 2',
            priceText: '₦360,000',
            stock: 0,
            status: ProductStatus.outOfStock,
          ),
          ProductItem(
            id: 'p3',
            name: 'LG OLED C2 55″',
            priceText: '₦2,150,000',
            stock: 3,
            status: ProductStatus.pending,
          ),
          ProductItem(
            id: 'p4',
            name: 'PS5 Slim',
            priceText: '₦790,000',
            stock: 12,
            status: ProductStatus.hidden,
          ),
        ],
      );

  @override
  List<Object?> get props => [query, filter, items];
}
