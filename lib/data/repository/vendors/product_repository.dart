import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/utils/korra_exception.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../models/product_model.dart';
import '../../models/vendor/vendor_stat.dart';
import 'vendor_repository.dart';

extension ProductRepository on VendorRepository {
 // 🔹 SECURE ADD (Calls Edge Function)
  Future<void> addProductSecure(Map<String, dynamic> productMap) async {
    try {
      debugPrint("🔒 Calling add-product-secure...");
      
      final response = await fx.invoke(
        'add-product-secure',
        body: {
          'vendorId': productMap['vendorId'],
          'productData': productMap, // Contains all fields including timeline
        },
      );

      final data = response.data;

      if (data['success'] != true) {
        throw KorraException(
          data['error'] ?? "Failed to create product",
          technicalDetails: "Server Validation Failed"
        );
      }

      debugPrint("✅ Product Created Successfully: ${data['data']['code']}");

    } catch (e) {
      debugPrint('Secure Upload Error: $e');
      if (e is FunctionException) {
         throw KorraException(
           "Server Error: ${e.reasonPhrase}", 
           technicalDetails: e.details.toString()
         );
      }
      rethrow;
    }
  }

  // Stream stats (Limit, Used, Available)
  Stream<VendorStats> streamVendorStats(String uid) {
    return firestore.collection('vendor_stats').doc(uid).snapshots().map((doc) {
      return VendorStats.fromFirestore(doc);
    });
  }

  Future<List<Product>> fetchProductsByVendor(String vendorId) async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching vendor products: $e');
      return [];
    }
  }

  // 🔹 Fetch a single product (using vendorId + code)
  Future<Product?> fetchSingleProduct(String vendorId, String code) async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Product.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching single product: $e');
      return null;
    }
  }

  // 🔹 SECURE EDIT
  Future<void> updateProductSecure({
    required String vendorId,
    required String productCode,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      debugPrint("🔒 Calling edit-product-secure...");
      
      final response = await fx.invoke(
        'edit-product-secure',
        body: {
          'vendorId': vendorId,
          'productCode': productCode,
          'updateData': updateData,
        },
      );

      final data = response.data;

      if (data['success'] != true) {
        throw KorraException(
          data['error'] ?? "Failed to update product",
          technicalDetails: "Server Limit Check Failed"
        );
      }

      debugPrint("✅ Product Updated: ${data['data']['status']}");

    } catch (e) {
      debugPrint('Secure Edit Error: $e');
      if (e is FunctionException) {
         throw KorraException(
           "Server Error: ${e.reasonPhrase}", 
           technicalDetails: e.details.toString()
         );
      }
      rethrow;
    }
  }

  // 🔹 Fetch products with pagination
  Future<List<Product>> fetchProductsByVendorPaginated({
    required String vendorId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = firestore
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching paginated products: $e');
      return [];
    }
  }

  /// 🔹 Stream vendor product items (real-time sync)
  Stream<List<ProductItem>> streamVendorProductItems(String vendorId) {
    final query = firestore
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs.map((doc) {
        final data = doc.data();

        return ProductItem(
          id: doc.id,
          name: data['name'] ?? '',
          code: data['code'] ?? '',
          priceText:
              '₦${(data['price'] is num) ? (data['price'] as num).toStringAsFixed(2) : data['price'] ?? ''}',
          description: data['description'] ?? '',
          category: data['category'] ?? 'Uncategorized',
          stock: data['availableStock'] ?? 0,
          status: ProductStatus.values.firstWhere(
            (s) => s.name == data['status'],
            orElse: () => ProductStatus.pending,
          ),
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              :  (data['createdAt'] as DateTime),
          imageUrl: (data['images'] is List)
              ? List<String>.from(data['images'])
              : (data['images'] != null ? [data['images'] as String] : []),
        );
      }).toList();

      // 🧠 Update local cache
      productItemCache
        ..clear()
        ..addAll(products);

      return List<ProductItem>.unmodifiable(productItemCache);
    });
  }

  /// 🔹 Read-only cache
  List<ProductItem> get cachedProductItems =>
      List<ProductItem>.unmodifiable(productItemCache);

  /// 🔹 Manual refresh (fetch once)
  Future<void> refreshVendorProductItems(String vendorId) async {
    final snapshot = await firestore
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final products = snapshot.docs.map((doc) {
      final data = doc.data();
      return ProductItem(
        id: doc.id,
        name: data['name'] ?? '',
        code: data['code'] ?? '',
        priceText:
            '₦${(data['price'] is num) ? (data['price'] as num).toStringAsFixed(2) : data['price'] ?? ''}',
        description: data['description'] ?? '',
        category: data['category'] ?? 'Uncategorized',
        stock: data['availableStock'] ?? 0,
        status: ProductStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => ProductStatus.pending,
        ),
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            :  (data['createdAt'] as DateTime),
        imageUrl: (data['images'] is List)
            ? List<String>.from(data['images'])
            : (data['images'] != null ? [data['images'] as String] : []),
      );
    }).toList();

    productItemCache
      ..clear()
      ..addAll(products);
  }

  Map<ProductStatus, int> get productStatusCounts {
    final counts = <ProductStatus, int>{};

    for (final item in productItemCache) {
      counts[item.status] = (counts[item.status] ?? 0) + 1;
    }

    return counts;
}

  Future<List<ProductItem>> fetchProducts({
    int limit = 10,
    String? startAfterId,
  }) async {
    Query query = firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterId != null) {
      final lastDoc = await firestore
          .collection('products')
          .doc(startAfterId)
          .get();
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint("Product data: $data");
      debugPrint("Product ID: ${doc.id}");
      debugPrint("Product images: ${data['images']}");
      debugPrint("Product status: ${data['status']}");
      debugPrint("Product price: ${data['price']}");
      debugPrint("Product stock: ${data['availableStock']}");
      debugPrint("Product category: ${data['category']}");
      debugPrint("Product description: ${data['description']}");
      debugPrint("Product name: ${data['name']}");
      debugPrint("Product code: ${data['code']}");
      debugPrint("Product vendorId: ${data['vendorId']}");

      return ProductItem(
        id: doc.id,
        name: data['name'] ?? '',
        code: data['code'] ?? '',
        priceText: '₦${(data['price'] as num).toStringAsFixed(2)}',
        description: data['description'] ?? '',
        category: data['category'] ?? 'Uncategorized',
        stock: data['availableStock'] ?? 0,
        status: ProductStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => ProductStatus.pending,
        ),
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            :  (data['createdAt'] as DateTime),
        imageUrl: (data['images'] is List)
            ? List<String>.from(data['images'])
            : (data['images'] != null ? [data['images'] as String] : []),
      );
    }).toList();
  }

  Future<String?> uploadToSupabase(File file) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // Upload image to your "product-images" bucket
      final response = await supabase.storage
          .from('product-images')
          .upload(fileName, file);

      // If upload succeeded, get public URL
      if (response.isEmpty) {
        return null;
      }

      final publicUrl = supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Supabase upload error: $e');
      return null;
    }
  }

  Future<List<String>> uploadProductImagesToCloud(List<File> images) async {
    List<String> uploadedUrls = [];

    for (var file in images) {
      final url = await uploadToSupabase(file);
      if (url != null) uploadedUrls.add(url);
    }

    return uploadedUrls;
  }

Future<void> deleteProductImages(List<String> imageUrls) async {
  for (final url in imageUrls) {
    final path = url.split('/').last;
    await supabase.storage.from('product-images').remove([path]);
  }
}
}

class ImageValidationResult {
  final bool success;
  final List<File> validImages;
  final List<String> errorMessages;

  ImageValidationResult({
    required this.success,
    required this.validImages,
    required this.errorMessages,
  });
}
