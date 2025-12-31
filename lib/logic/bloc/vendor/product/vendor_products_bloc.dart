import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../data/models/vendor/vendor_stat.dart';
import '../../../../data/repository/vendors/product_repository.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../../presentation/vendor/product/widgets/share_link_sheet.dart';
import '../../../core/net/net_cubit.dart';
import 'vendor_products_event.dart';
import 'vendor_products_state.dart';

class VendorProductsBloc
    extends Bloc<VendorProductsEvent, VendorProductsState> {
  final VendorRepository vendors;
  final String vendorUid;
  final NetCubit net;

  VendorProductsBloc({
    required this.vendors,
    required this.vendorUid,
    required this.net,
  }) : super(VendorProductsState.initial()) {
    on<VendorProductsStarted>(_onStarted);
    on<VendorProductsRefresh>(_onRefresh);
    on<VendorProductsQueryChanged>(_onQueryChanged);
    on<VendorProductsFilterChanged>(_onFilterChanged);
    on<VendorProductsAdd>(_onAddPressed);
    on<VendorProductsSharePressed>(_onSharePressed);
    on<VendorProductsEdit>(_onEditProduct);
    on<VendorProductsRestockPressed>(_onRestockPressed);
    on<VendorProductsRequested>(_productsRequested);
    on<VendorProductsUpdated>(_productsUpdated);
    on<VendorProductsLoadMore>(_productsLoadMore);
  }

  // Event Handlers 
  Future<void> _onStarted(
    VendorProductsStarted event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state); 

    // Subscribe to Vendor Stats (Real-time Limit updates)
    final statsStream = vendors.streamVendorStats(vendorUid);
    
    add(VendorProductsRequested());

    await emit.forEach<VendorStats>(
      statsStream,
      onData: (stats) => state.copyWith(
        availableLimit: stats.remainingLimit, 
      ),
      onError: (e, s) {
        debugPrint("Error fetching stats: $e");
        return state;
      } 
    );
  }

  Future<void> _onRefresh(
    VendorProductsRefresh event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state); 
    add(VendorProductsRequested());
  }

  void _onQueryChanged(
    VendorProductsQueryChanged event,
    Emitter<VendorProductsState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  void _onFilterChanged(
    VendorProductsFilterChanged event,
    Emitter<VendorProductsState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }
  
  Future<void> _onAddPressed(
    VendorProductsAdd event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, success: false));

    try {
      debugPrint('🚀 Starting Product Creation...');

      if (event.images.isEmpty) {
        emit(state.copyWith(
          isSubmitting: false, 
          errorMessage: "Please upload at least one product image."
        ));
        return;
      }

      debugPrint('📤 Uploading images...');
      
      // 🔄 FIX: Remove the 'map(path => File(path))' logic.
      // The event.images already contains the File/XFile objects we need.
      // We pass the list directly to the repo.
      
      final List<String> uploadedUrls = await vendors.uploadProductImagesToCloud(
        event.images, // ✅ Pass List<dynamic> directly
      );

      if (uploadedUrls.isEmpty) {
        throw "Failed to upload images. Please check your internet connection.";
      }

      // ... (Rest of the duration calculation remains the same) ...
      final baseDays = event.duration;
      final noticeDays = 3;
      int extDays = 0;
      if (event.extensionsEnabled) {
         final p = event.price;
         if (p <= 20000) extDays = 7;
         else if (p <= 40000) extDays = 7;
         else if (p <= 150000) extDays = 14;
         else if (p <= 320000) extDays = 15;
         else extDays = 20;
      }
      final totalDays = baseDays + noticeDays + extDays;

      final newProductMap = {
        'vendorId': vendorUid,
        'storeName': await vendors.getStoreName(vendorUid), 
        'name': event.name,
        'description': event.description,
        'price': event.price,
        'availableStock': event.stock,
        'initialStock': event.stock,
        'category': event.category,
        'images': uploadedUrls,
        'modelType': event.modelType.name, 
        'cancellationPolicy': event.cancellationPolicy,
        'extensionsEnabled': event.extensionsEnabled,
        'directDownPayment': event.directDownPayment,
        'duration': baseDays, 
        'baseDuration': "$baseDays Days",
        'noticePeriod': "$noticeDays Days",
        'totalMaxTime': "$totalDays Days",
      };

      await vendors.addProductSecure(newProductMap);

      emit(state.copyWith(isSubmitting: false, success: true));

    } catch (e) {
      debugPrint("❌ Add Product Error: $e");
      emit(state.copyWith(
        isSubmitting: false, 
        errorMessage: e.toString().replaceAll("Exception:", "").trim()
      ));
    }
  }

  Future<void> _onEditProduct(
    VendorProductsEdit event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final currentProduct = await vendors.fetchSingleProduct(vendorUid, event.productCode);
      if (currentProduct == null) throw "Product not found.";

      List<String> finalImages = [...event.existingImageUrls];
      
      if (event.newImages.isNotEmpty) {
        // ✅ Pass List<dynamic> directly here too
        final newUrls = await vendors.uploadProductImagesToCloud(event.newImages);
        if (newUrls.isEmpty) throw "Failed to upload new images.";
        finalImages.addAll(newUrls);
      }

      if (finalImages.isEmpty) throw "Product must have at least one image.";

      final updateData = {
        'name': event.name,
        'description': event.description,
        'price': event.price,
        'availableStock': event.stock, 
        'category': event.category,
        'images': finalImages,
      };

      await vendors.updateProductSecure(
        vendorId: vendorUid,
        productCode: event.productCode,
        updateData: updateData,
      );

      emit(state.copyWith(isSubmitting: false, success: true));
      add(const VendorProductsRefresh());

    } catch (e) {
      debugPrint("❌ Edit Error: $e");
      emit(state.copyWith(
        isSubmitting: false, 
        errorMessage: e.toString().replaceAll("Exception:", "").trim()
      ));
    }
  }

  Future<void> _onSharePressed(
    VendorProductsSharePressed event,
    Emitter<VendorProductsState> emit,
  ) async {
    final product = event.product;

    if (!product.shareable) {
      Get.snackbar(
        'Unavailable',
        'Link will be available after approval and if in stock.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await ShareLinkSheet.show(Get.context!, product);
  }

  void _onRestockPressed(
    VendorProductsRestockPressed event,
    Emitter<VendorProductsState> emit,
  ) {
    Get.snackbar(
      'Restock',
      'Restock ${event.productId}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  StreamSubscription<List<ProductItem>>? _productsStreamSub;

  Map<ProductFilter, int> _calculateStatusCounts(List<ProductItem> products) {
    final counts = <ProductFilter, int>{
      ProductFilter.all: products.length,
      ProductFilter.approved: 0,
      ProductFilter.pending: 0,
      ProductFilter.rejected: 0,
      ProductFilter.outOfStock: 0,
    };

    for (final p in products) {
      switch (p.status) {
        case ProductStatus.approved:
          counts[ProductFilter.approved] =
              (counts[ProductFilter.approved] ?? 0) + 1;
          break;
        case ProductStatus.pending:
          counts[ProductFilter.pending] =
              (counts[ProductFilter.pending] ?? 0) + 1;
          break;
        case ProductStatus.rejected:
          counts[ProductFilter.rejected] =
              (counts[ProductFilter.rejected] ?? 0) + 1;
          break;
        case ProductStatus.outOfStock:
          counts[ProductFilter.outOfStock] =
              (counts[ProductFilter.outOfStock] ?? 0) + 1;
          break;
      }
    }

    return counts;
  }

  Future<void> _productsRequested(
    VendorProductsRequested event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    debugPrint('🔹 Fetching vendor products...');

    try {
      await vendors.refreshVendorProductItems(vendorUid);
      final cached = vendors.cachedProductItems;
      debugPrint("🔹 Cached products: ${cached.length}");

      final cachedCounts = _calculateStatusCounts(cached);

      emit(state.copyWith(
        items: cached.take(10).toList(),
        isSubmitting: false,
        statusCounts: cachedCounts,
      ));

      await _productsStreamSub?.cancel();
      _productsStreamSub =
          vendors.streamVendorProductItems(vendorUid).listen((updatedList) {
        final liveCounts = _calculateStatusCounts(updatedList);
        add(VendorProductsUpdated(updatedList, liveCounts));
      });
    } catch (e, st) {
      debugPrint('❌ Error fetching products: $e\n$st');
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> _productsLoadMore(
    VendorProductsLoadMore event,
    Emitter<VendorProductsState> emit,
  ) async {
    final all = vendors.cachedProductItems;
    final current = state.items.length;

    if (current >= all.length) {
      debugPrint("⚠️ No more products to load.");
      return;
    }

    final nextBatch = all.skip(current).take(10).toList();
    emit(state.copyWith(items: [...state.items, ...nextBatch]));
  }

  @override
  Future<void> close() {
    _productsStreamSub?.cancel();
    return super.close();
  }

  Future<void> _productsUpdated(
    VendorProductsUpdated event,
    Emitter<VendorProductsState> emit,
  ) async {
    debugPrint("♻️ Products updated from Firestore stream (${event.items.length})");

    final int targetLength = math.max(state.items.length, 20);

    emit(state.copyWith(
      items: event.items.take(targetLength).toList(),
      statusCounts: event.statusCounts ?? state.statusCounts,
    ));
  }
}