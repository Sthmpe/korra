import '../../product_model.dart';

class ProductCount {
  final int total;
  final int active;
  final int paused;
  final int outOfStock;

  ProductCount({
    required this.total,
    required this.active,
    required this.paused,
    required this.outOfStock,
  });
}

ProductCount getProductCounts(List<Product> products) {
  int active = 0, paused = 0, outOfStock = 0;

  for (var p in products) {
    if (p.status == 'active') active++;
    if (p.status == 'paused') paused++;
    if ((p.availableStock ?? 0) <= 0) outOfStock++;
  }

  return ProductCount(
    total: products.length,
    active: active,
    paused: paused,
    outOfStock: outOfStock,
  );
}
