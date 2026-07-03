// lib/presentation/customer/storefront/widgets/cart_service.dart

import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';

class CartItem {
  final String productId;
  final String productCode;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productCode,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productCode': productCode,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productCode: map['productCode'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: ((map['price'] ?? 0.0) as num).toDouble(),
      quantity: (map['quantity'] ?? 1) as int,
    );
  }
}

class CartService {
  static final CartService instance = CartService._internal();
  CartService._internal();

  // Maps vendorId to a list of CartItems
  final ValueNotifier<Map<String, List<CartItem>>> cartsNotifier = ValueNotifier({});

  List<CartItem> getItems(String vendorId) {
    return cartsNotifier.value[vendorId] ?? [];
  }

  int getCartCount(String vendorId) {
    final items = getItems(vendorId);
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  void addToCart(String vendorId, Product product, int quantity) {
    final currentCarts = Map<String, List<CartItem>>.from(cartsNotifier.value);
    final items = List<CartItem>.from(currentCarts[vendorId] ?? []);

    final finalPrice = (product.discountedPrice != null && product.discountedPrice! > 0)
        ? product.discountedPrice!
        : product.price;

    final existingIndex = items.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(CartItem(
        productId: product.id,
        productCode: product.code,
        name: product.name,
        imageUrl: product.images.isNotEmpty ? product.images.first : '',
        price: finalPrice,
        quantity: quantity,
      ));
    }

    currentCarts[vendorId] = items;
    cartsNotifier.value = currentCarts;
  }

  void updateQuantity(String vendorId, String productId, int delta) {
    final currentCarts = Map<String, List<CartItem>>.from(cartsNotifier.value);
    final items = List<CartItem>.from(currentCarts[vendorId] ?? []);

    final index = items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final newQty = items[index].quantity + delta;
      if (newQty <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = newQty;
      }
    }

    if (items.isEmpty) {
      currentCarts.remove(vendorId);
    } else {
      currentCarts[vendorId] = items;
    }
    cartsNotifier.value = currentCarts;
  }

  void removeItem(String vendorId, String productId) {
    final currentCarts = Map<String, List<CartItem>>.from(cartsNotifier.value);
    final items = List<CartItem>.from(currentCarts[vendorId] ?? []);

    items.removeWhere((item) => item.productId == productId);

    if (items.isEmpty) {
      currentCarts.remove(vendorId);
    } else {
      currentCarts[vendorId] = items;
    }
    cartsNotifier.value = currentCarts;
  }

  void clearCart(String vendorId) {
    final currentCarts = Map<String, List<CartItem>>.from(cartsNotifier.value);
    currentCarts.remove(vendorId);
    cartsNotifier.value = currentCarts;
  }
}
