import 'dart:async';

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
    // 1. Load Initial State
    emit(state); 

    // 2. Subscribe to Vendor Stats (Real-time Limit updates)
    // We use emit.forEach to keep the state updated automatically
    final statsStream = vendors.streamVendorStats(vendorUid);
    
    // Start listening to products immediately
    add(VendorProductsRequested());

    // Listen to stats indefinitely
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
    emit(state); // TODO: pull from repository
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
    // 1. Start Loading
    emit(state.copyWith(isSubmitting: true, errorMessage: null, success: false));

    try {
      debugPrint('🚀 Starting Product Creation...');

      // 2. Image Validation
      if (event.images.isEmpty) {
        emit(state.copyWith(
          isSubmitting: false, 
          errorMessage: "Please upload at least one product image."
        ));
        return;
      }

      // 3. Upload Images
      debugPrint('📤 Uploading images...');
      final List<String> uploadedUrls = await vendors.uploadProductImagesToCloud(
        event.images, 
      );

      if (uploadedUrls.isEmpty) {
        throw "Failed to upload images. Please check your internet connection.";
      }

      // 4. Calculate Timeline (Backend Logic Mirror)
      // We calculate this here so it's ready for the DB.
      final timeline = _calculateTimeline(event.price, event.modelType, event.extensionsEnabled);

      // 5. Prepare Data Payload
      // Note: We do NOT generate ID, Code, or Status here. The Server does that.
      final newProductMap = {
        'vendorId': vendorUid,
        'storeName': await vendors.getStoreName(vendorUid), 
        'name': event.name,
        'description': event.description,
        'price': event.price,
        'availableStock': event.stock, // "stock" from UI maps to "availableStock"
        'initialStock': event.stock,
        'category': event.category,
        'images': uploadedUrls,
        
        // Smart Contract Fields
        'modelType': event.modelType.name, 
        'cancellationPolicy': event.cancellationPolicy,
        'extensionsEnabled': event.extensionsEnabled,
        'directDownPayment': event.directDownPayment,
        
        // Timeline Fields
        'baseDuration': timeline['baseDuration'],
        'noticePeriod': timeline['noticePeriod'],
        'totalMaxTime': timeline['totalMaxTime'],
      };

      // 6. Call Secure Repository
      await vendors.addProductSecure(newProductMap);

      // 7. Success
      emit(state.copyWith(
        isSubmitting: false, 
        success: true
      ));

    } catch (e) {
      debugPrint("❌ Add Product Error: $e");
      emit(state.copyWith(
        isSubmitting: false, 
        errorMessage: e.toString().replaceAll("Exception:", "").trim()
      ));
    }
  }

  // --- HELPER: Timeline Logic ---
  Map<String, String> _calculateTimeline(double price, ProductModelType model, bool extEnabled) {
    int baseDays = 15;
    int noticeDays = 1;
    int extDays = 0;
    bool priceAllowsExt = false;

    // 1. Base Logic
    if (price <= 7000) {
      baseDays = 15; noticeDays = 1; priceAllowsExt = false;
    } else if (price <= 15000) {
      baseDays = 25; noticeDays = 2; priceAllowsExt = false;
    } else if (price <= 20000) {
      baseDays = 30; noticeDays = 3; extDays = 7; priceAllowsExt = true;
    } else if (price <= 25000) {
      baseDays = 30; noticeDays = 3; extDays = 15; priceAllowsExt = true;
    } else if (price <= 35000) {
      baseDays = 45; noticeDays = 5; extDays = 15; priceAllowsExt = true;
    } else if (price <= 50000) {
      baseDays = 45; noticeDays = 10; extDays = 21; priceAllowsExt = true;
    } else if (price <= 75000) {
      baseDays = 90; noticeDays = 10; extDays = 21; priceAllowsExt = true;
    } else {
      baseDays = 90; noticeDays = 10; extDays = 30; priceAllowsExt = true;
    }

    // 2. Direct Model Override (Your specific rule)
    if (model == ProductModelType.direct) {
      if (!extEnabled) {
        noticeDays = 3; // Fixed 3 days if no extension in Direct
        extDays = 0;
      }
    } else {
      // Strict Model: Extension logic follows price table
      if (!priceAllowsExt) extDays = 0;
    }

    // 3. Totals
    int total = baseDays + noticeDays + extDays;

    return {
      'baseDuration': "$baseDays Days",
      'noticePeriod': "$noticeDays Days",
      'totalMaxTime': "$total Days",
    };
  }

Future<void> _onEditProduct(
    VendorProductsEdit event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      // 1. Fetch Current Record (To get modelType for timeline calc)
      final currentProduct = await vendors.fetchSingleProduct(vendorUid, event.productCode);
      if (currentProduct == null) throw "Product not found.";

      // 2. Handle Images
      List<String> finalImages = [...event.existingImageUrls];
      if (event.newImages.isNotEmpty) {
        final newUrls = await vendors.uploadProductImagesToCloud(event.newImages);
        if (newUrls.isEmpty) throw "Failed to upload new images.";
        finalImages.addAll(newUrls);
      }

      if (finalImages.isEmpty) throw "Product must have at least one image.";

      // 3. Recalculate Timeline (Important!)
      // Price change = New Duration rules
      final timeline = _calculateTimeline(
        event.price, 
        // We use the existing model type unless you allow changing model on edit (rare)
        // Assuming currentProduct has the type. If event has it, use event.
        currentProduct.modelType, 
        currentProduct.extensionsEnabled
      );

      // 4. Prepare Update Payload
      final updateData = {
        'name': event.name,
        'description': event.description,
        'price': event.price,
        'availableStock': event.stock, // UI "stock" -> DB "availableStock"
        // Note: We usually don't update 'initialStock' on edit, just available.
        'category': event.category,
        'images': finalImages,
        
        // Update Timeline (Server saves this)
        'baseDuration': timeline['baseDuration'],
        'noticePeriod': timeline['noticePeriod'],
        'totalMaxTime': timeline['totalMaxTime'],
      };

      // 5. Call Secure Update
      await vendors.updateProductSecure(
        vendorId: vendorUid,
        productCode: event.productCode,
        updateData: updateData,
      );

      // 6. Success
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

    await ShareLinkSheet.show(
      Get.context!,
      productName: product.name,
      token: product.code,
    );
  }

  void _onRestockPressed(
    VendorProductsRestockPressed event,
    Emitter<VendorProductsState> emit,
  ) {
    // TODO restock flow
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
    // 1️⃣ Refresh the first batch (local cache)
    await vendors.refreshVendorProductItems(vendorUid);
    final cached = vendors.cachedProductItems;
    debugPrint("🔹 Cached products: ${cached.length}");

    // 2️⃣ Compute counts for cached items
    final cachedCounts = _calculateStatusCounts(cached);

    // 3️⃣ Emit cached immediately
    emit(state.copyWith(
      items: cached.take(10).toList(),
      isSubmitting: false,
      statusCounts: cachedCounts,
    ));

    // 4️⃣ Start listening to real-time stream updates
    await _productsStreamSub?.cancel();
    _productsStreamSub =
        vendors.streamVendorProductItems(vendorUid).listen((updatedList) {
      // 🧮 Compute new counts from live updates
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

  emit(state.copyWith(
    items: event.items.take(state.items.length).toList(), // keep pagination limit
    statusCounts: event.statusCounts ?? state.statusCounts,
  ));
}
}
