// lib/presentation/customer/storefront/widgets/cart_service.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Carts persist across app launches (SharedPreferences) so we can nudge
/// customers back to unfinished checkouts. Each vendor cart auto-expires
/// [cartLifetime] after its last update.
class CartService {
  static final CartService instance = CartService._internal();
  CartService._internal();

  static const String _prefsKey = 'korra_saved_carts_v2';
  static const Duration cartLifetime = Duration(days: 7);

  // Maps vendorId to a list of CartItems
  final ValueNotifier<Map<String, List<CartItem>>> cartsNotifier = ValueNotifier({});

  /// Last-touched time per vendor cart, used for the 1-week auto-delete.
  final Map<String, DateTime> _savedAt = {};
  bool _loaded = false;

  /// Vendors with an unfinished checkout — drives the nav-bar signal badge
  /// and the red dots / ranking on the Stores page.
  Set<String> get pendingVendorIds => cartsNotifier.value.keys.toSet();
  bool get hasAnyCart => cartsNotifier.value.isNotEmpty;

  /// Load saved carts from disk and purge expired ones. Safe to call more
  /// than once; only the first call does work.
  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final restored = <String, List<CartItem>>{};
      final now = DateTime.now();

      decoded.forEach((vendorId, value) {
        final entry = value as Map<String, dynamic>;
        final savedAt = DateTime.tryParse(entry['savedAt'] ?? '') ?? now;
        if (now.difference(savedAt) > cartLifetime) return; // expired — drop

        final items = (entry['items'] as List<dynamic>? ?? [])
            .map((m) => CartItem.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (items.isEmpty) return;

        restored[vendorId] = items;
        _savedAt[vendorId] = savedAt;
      });

      if (restored.isNotEmpty) cartsNotifier.value = restored;
      if (restored.length != decoded.length) _persist(); // rewrite without expired
    } catch (e) {
      debugPrint('CartService: failed to restore carts: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{};
      cartsNotifier.value.forEach((vendorId, items) {
        payload[vendorId] = {
          'savedAt': (_savedAt[vendorId] ?? DateTime.now()).toIso8601String(),
          'items': items.map((i) => i.toMap()).toList(),
        };
      });
      await prefs.setString(_prefsKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('CartService: failed to save carts: $e');
    }
  }

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
    _savedAt[vendorId] = DateTime.now();
    cartsNotifier.value = currentCarts;
    _persist();
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
      _savedAt.remove(vendorId);
    } else {
      currentCarts[vendorId] = items;
      _savedAt[vendorId] = DateTime.now();
    }
    cartsNotifier.value = currentCarts;
    _persist();
  }

  void removeItem(String vendorId, String productId) {
    final currentCarts = Map<String, List<CartItem>>.from(cartsNotifier.value);
    final items = List<CartItem>.from(currentCarts[vendorId] ?? []);

    items.removeWhere((item) => item.productId == productId);

    if (items.isEmpty) {
      currentCarts.remove(vendorId);
      _savedAt.remove(vendorId);
    } else {
      currentCarts[vendorId] = items;
      _savedAt[vendorId] = DateTime.now();
    }
    cartsNotifier.value = currentCarts;
    _persist();
  }

  void clearCart(String vendorId) {
    final currentCarts = Map<String, List<CartItem>>.from(cartsNotifier.value);
    currentCarts.remove(vendorId);
    _savedAt.remove(vendorId);
    cartsNotifier.value = currentCarts;
    _persist();
  }
}