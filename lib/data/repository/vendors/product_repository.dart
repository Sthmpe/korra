import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/utils/korra_exception.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../models/vendor/vendor_stat.dart';
import 'vendor_repository.dart';

extension ProductRepository on VendorRepository {
  
  // 🔹 SECURE ADD (Calls Edge Function)
  Future<void> addProductSecure(Map<String, dynamic> productMap) async {
    try {
      final user = auth.currentUser;

      if (user == null) throw "You must be logged in.";

      // 1. Get the User VIP Pass (Who they are)
      final idToken = await user.getIdToken(true);

      // 2. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("User ID: ${user.uid}");
      debugPrint("🔒 Calling add-product-secure with Double Lock...");

      final response = await fx.invoke(
        'add-product-secure',
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
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

  // 🔹 Fetch a single product (using vendorId + code)
  Future<ProductItem?> fetchSingleProduct(String vendorId, String code) async {
    try {
      final snapshot = await firestore
          .collection('products')
          .where('vendorId', isEqualTo: vendorId)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        // ✅ USE fromJson
        return ProductItem.fromJson(doc.data(), doc.id);
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
      final user = auth.currentUser;

      if (user == null) throw "You must be logged in.";

      // 1. Get the User VIP Pass (Who they are)
      final idToken = await user.getIdToken(true);

      // 2. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("User ID: ${user.uid}");
      debugPrint("🔒 Calling edit-product-secure with Double Lock...");
      
      final response = await fx.invoke(
        'edit-product-secure',
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
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

  /// 🔹 Stream vendor product items (real-time sync)
  Stream<List<ProductItem>> streamVendorProductItems(String vendorId, {int limit = 10}) {
    final query = firestore
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs.map((doc) {
        // ✅ CLEANER: Delegate mapping to the Model class
        return ProductItem.fromJson(doc.data(), doc.id);
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
  Future<void> refreshVendorProductItems(String vendorId, {int limit = 10}) async {
    final snapshot = await firestore
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    final products = snapshot.docs.map((doc) {
      // ✅ CLEANER: Delegate mapping to the Model class
      return ProductItem.fromJson(doc.data(), doc.id);
    }).toList();

    productItemCache
      ..clear()
      ..addAll(products);
  }

  // Calculate status counts from cache
  Map<ProductStatus, int> get productStatusCounts {
    final counts = <ProductStatus, int>{};

    for (final item in productItemCache) {
      counts[item.status] = (counts[item.status] ?? 0) + 1;
    }

    return counts;
  }

  // General Fetch
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
      // ✅ CLEANER: Delegate mapping to the Model class
      return ProductItem.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // --- IMAGE UPLOAD LOGIC ---

  // 🔄 UPDATED: Accepts List<dynamic> to support File (Mobile) and XFile (Web)
  Future<List<String>> uploadProductImagesToCloud(List<dynamic> images) async {
    List<String> uploadedUrls = [];

    for (var image in images) {
      // We pass the dynamic image object directly
      final url = await uploadToSupabase(image);
      if (url != null) uploadedUrls.add(url);
    }

    return uploadedUrls;
  }

  Future<String?> uploadToSupabase(dynamic fileInput) async {
    try {
      final String fileName;
      
      // 1. DETERMINE FILENAME
      if (kIsWeb) {
        // On web, fileInput is XFile
        if (fileInput is XFile) {
           fileName = '${DateTime.now().millisecondsSinceEpoch}_${fileInput.name}';
        } else {
           throw "Expected XFile on Web";
        }
      } else {
        // On mobile, fileInput is File
        if (fileInput is File) {
           fileName = '${DateTime.now().millisecondsSinceEpoch}_${fileInput.path.split('/').last}';
        } else if (fileInput is XFile) {
           // Fallback if XFile is passed on mobile
           fileName = '${DateTime.now().millisecondsSinceEpoch}_${fileInput.name}';
        } else {
           throw "Invalid File Type";
        }
      }

      // 2. PERFORM UPLOAD
      if (kIsWeb) {
        // 🌐 WEB: Upload Raw Bytes using uploadBinary
        // We must read as bytes because File() doesn't exist on web
        final bytes = await (fileInput as XFile).readAsBytes();
        
        await supabase.storage
            .from('product-images')
            .uploadBinary(
              fileName, 
              bytes,
              fileOptions: const FileOptions(upsert: true), // Optional: Overwrite if exists
            );

      } else {
        // 📱 MOBILE: Upload using File object
        // If it's an XFile on mobile, convert to File first
        File fileToUpload = (fileInput is File) 
            ? fileInput 
            : File((fileInput as XFile).path);

        await supabase.storage
            .from('product-images')
            .upload(
              fileName, 
              fileToUpload,
              fileOptions: const FileOptions(upsert: true),
            );
      }

      // 3. GET PUBLIC URL
      final publicUrl = supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

      return publicUrl;

    } catch (e) {
      debugPrint('❌ Supabase upload error: $e');
      return null;
    }
  }

  Future<void> deleteProductImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      final path = url.split('/').last;
      await supabase.storage.from('product-images').remove([path]);
    }
  }

  /// 🔹 Delete Product
  Future<void> deleteProductSecure(String vendorId, String productId, String type)async {
    try {
      final user = auth.currentUser;

      if (user == null) throw "You must be logged in.";

      // 1. Get the User VIP Pass (Who they are)
      final idToken = await user.getIdToken(true);

      // 2. Get the Device VIP Pass (Proves it is the real Korra app, not a bot)
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Do the Math: Hash the timestamp using the secret key
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final digest = hmacSha256.convert(utf8.encode(timestamp));
      final signature = digest.toString();

      debugPrint("User ID: ${user.uid}");
      debugPrint("🔒 Calling delete-product-secure with Double Lock...");
      
      final response = await fx.invoke(
        'delete-product-secure',
        headers: {
          'firebase-token': 'Bearer $idToken',  // 🔐 Lock 2: User Identity
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'type': type,
          'vendorUid': vendorId,
          'productId': productId,
        },
      );

      final data = response.data;

      if (data['success'] != true) {
        throw KorraException(
          data['error'] ?? "Failed to delete product",
          technicalDetails: "Server Validation Failed"
        );
      }

      debugPrint("✅ Product Deleted Successfully: $productId");

    } catch (e) {
      debugPrint('Secure Delete Error: $e');
      if (e is FunctionException) {
         throw KorraException(
           "Server Error: ${e.reasonPhrase}", 
           technicalDetails: e.details.toString()
         );
      }
      rethrow;
    }
  }

  /// 🔹 Delete Multiple Products Securely (Group Delete)
  Future<void> deleteMultipleProductsSecure(String vendorId, List<String> productIds) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw "You must be logged in.";

      final idToken = await user.getIdToken(true);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacSha256 = Hmac(sha256, utf8.encode(korraSecret));
      final signature = hmacSha256.convert(utf8.encode(timestamp)).toString();

      debugPrint("🔒 Calling secure multi-delete for ${productIds.length} items...");
      
      final response = await fx.invoke(
        'delete-product-secure',
        headers: {
          'firebase-token': 'Bearer $idToken', 
          'x-korra-timestamp': timestamp,
          'x-korra-signature': signature,
        },
        body: {
          'type': 'multiple-delete', // 🚀 NEW TYPE
          'vendorUid': vendorId,
          'productIds': productIds,  // 🚀 PASS THE LIST
        },
      );

      dynamic data = response.data;
      if (data is String) data = jsonDecode(data); // Safety net

      if (data['success'] != true) throw Exception(data['error'] ?? "Failed to delete products");

    } catch (e) {
      debugPrint('Secure Multi-Delete Error: $e');
      if (e is FunctionException) {
         throw KorraException(
           "Server Error: ${e.reasonPhrase}", 
           technicalDetails: e.details.toString()
         );
      }
      rethrow;
    }
  }

  /// 🔹 Fetch counts for product tabs (All, Approved, Pending, Rejected, Out of Stock)
  Future<Map<ProductFilter, int>> fetchProductTabCounts(String vendorId) async {
    final baseQuery = firestore.collection('products').where('vendorId', isEqualTo: vendorId);

    // Run all count queries simultaneously for speed
    final results = await Future.wait([
      baseQuery.count().get(), // All
      baseQuery.where('status', isEqualTo: 'approved').where('availableStock', isGreaterThan: 0).count().get(), // Approved & In Stock
      baseQuery.where('status', isEqualTo: 'pending').count().get(), // Pending
      baseQuery.where('status', isEqualTo: 'rejected').count().get(), // Rejected
      baseQuery.where('availableStock', isLessThanOrEqualTo: 0).count().get(), // Out of Stock
    ]);

    return {
      ProductFilter.all: results[0].count ?? 0,
      ProductFilter.approved: results[1].count ?? 0,
      ProductFilter.pending: results[2].count ?? 0,
      ProductFilter.rejected: results[3].count ?? 0,
      ProductFilter.outOfStock: results[4].count ?? 0,
    };
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