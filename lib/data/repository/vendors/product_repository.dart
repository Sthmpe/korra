import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../models/product_model.dart';
import 'vendor_repository.dart';

extension ProductRepository on VendorRepository {
  Future<Product?> addProduct(Product product) async {
    try {
      final docRef = firestore.collection('products').doc();
      final newProduct = product.copyWith(id: docRef.id);

      await docRef.set(newProduct.toMap());

      return newProduct;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return null;
    }
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

  // 🔹 Update product (using vendorId + code)
  Future<bool> updateProduct({
    required String vendorId,
    required String productCode,
    required Product updatedProduct,
  }) async {
    try {
      // --- 1️⃣ Fetch the product by vendorId and code ---
      final snapshot = await firestore
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .where('code', isEqualTo: productCode)
          .limit(1)
          .get();

        if (snapshot.docs.isEmpty) {
          debugPrint("❌ Product not found for vendorId=$vendorId, code=$productCode");
          return false;
        }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final oldProduct = Product.fromMap(data, doc.id);

      // ---2️⃣ Push update to Firestore ---
      await firestore
          .collection('products')
          .doc(oldProduct.id)
          .update(updatedProduct.toMap());

      debugPrint("✅ Product updated successfully for code=$productCode");
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
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

  Future<ImageValidationResult> validateProductImagesWithAI(
    List<File> images, {
    String? description,
    String? category,
  }) async {
    List<File> validImages = [];
    List<String> errorMessages = [];

    for (var img in images) {
      try {
        final bytes = await img.readAsBytes();
        final imagePart = InlineDataPart('image/jpeg', bytes);

        final model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash-lite-001',
        );

        final prompt = TextPart("""
        You are checking if a product image is suitable for an e-commerce platform where vendors upload products.

        Product Description: "${description ?? "N/A"}"
        Product Category: "${category ?? "N/A"}"

        Evaluate the image based on real-world vendor uploads — not perfection. 
        Be lenient with lighting or background issues as long as the product is clear and relevant.

        Return **only raw JSON** with no explanation, no markdown, and no code block:
        {
          "isValidProductImage": true/false, // true if it clearly shows a real product
          "matchesDescription": true/false, // true if it visually fits the description
          "matchesCategory": true/false, // true if it belongs in the stated category
          "recommendedCategory": "string", // suggest best-fit category if mismatch
          "isGoodForUpload": true/false, // true if overall acceptable for listing
          "reason": "short explanation for result"
        }
        """);

        final response = await model.generateContent([
          Content.multi([prompt, imagePart]),
        ]);

        var rawText = response.text ?? "{}";

        debugPrint("AI response: $rawText");

        // 🧹 Clean markdown fences and stray spaces
        final cleaned = rawText
            .replaceAll(RegExp(r'```json|```', caseSensitive: false), '')
            .trim();

        debugPrint("Cleaned JSON: $cleaned");

        // 🧩 Safe decode
        Map<String, dynamic> result;
        try {
          result = jsonDecode(cleaned);
        } catch (e) {
          debugPrint("AI returned invalid JSON after cleanup: $cleaned");
          errorMessages.add("AI returned unreadable result for an image.");
          continue;
        }

        final isValid =
            result["isValidProductImage"] == true &&
            result["isGoodForUpload"] == true;

        if (isValid) {
          validImages.add(img);
        } else {
          errorMessages.add(result["reason"] ?? "Unknown issue with image.");
        }

        await Future.delayed(
          const Duration(seconds: 3),
        ); // To avoid rate limits
      } catch (e) {
        debugPrint("AI validation error: $e");
        errorMessages.add("AI validation error: $e");
      }
    }

    if (validImages.length < 3) {
      errorMessages.add(
        "You need at least 3 valid images to upload this product.",
      );
      return ImageValidationResult(
        success: false,
        validImages: validImages,
        errorMessages: errorMessages,
      );
    }

    return ImageValidationResult(
      success: true,
      validImages: validImages,
      errorMessages: [],
    );
  }

  Future<bool> validateProductPrice(String category, int price) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.functions.invoke(
        'validate-product-price', // <-- your Supabase Edge Function name
        body: {'category': category, 'price': price},
      );

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;
        final valid = data['valid'] as bool? ?? false;

        if (success && valid) {
          return true; // ✅ Price is valid
        }
      }
      return false; // ❌ Invalid
    } catch (e) {
      debugPrint("Error validating price: $e");
      return false;
    }
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
