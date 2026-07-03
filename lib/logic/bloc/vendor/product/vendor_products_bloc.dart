import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
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
    on<VendorProductsDelete>(_onDeleteProduct);
    on<VendorProductsToggleSelection>(_onToggleSelection);
    on<VendorProductsSelectAll>(_onSelectAll);
    on<VendorProductsClearSelection>(_onClearSelection);
    on<VendorProductsDeleteMultiple>(_onDeleteMultiple);
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
    emit(state.copyWith(
      query: event.query,
      flow: ProductFlow.idle, // 🚀 Reset flow
      errorMessage: null,     // 🚀 Clear old errors
    ));
  }

  void _onFilterChanged(
    VendorProductsFilterChanged event,
    Emitter<VendorProductsState> emit,
  ) {
    emit(state.copyWith(
      filter: event.filter,
      flow: ProductFlow.idle, // 🚀 Reset flow
      errorMessage: null,     // 🚀 Clear old errors
    ));
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
      final noticeDays = event.noticePeriod;
      final extDays = event.extensionPeriod;
      
      final totalDays = baseDays + noticeDays + (event.extensionsEnabled ? extDays : 0);

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
        'allowReservation': event.allowReservation,
        'isFeatured': event.isFeatured,
      };

      await vendors.addProductSecure(newProductMap);

      await FirebaseAnalytics.instance.logEvent(
        name: 'product_added',
        parameters: {
          'vendor_id': vendorUid,
          'product_name': event.name,
          'price': event.price,
          'category': event.category,
        },
      );

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
        'allowReservation': event.allowReservation,
        'modelType': event.modelType.name,
        'cancellationPolicy': event.cancellationPolicy,
        'extensionsEnabled': event.extensionsEnabled,
        'directDownPayment': event.directDownPayment,
        'baseDuration': "${event.duration} Days",
        'noticePeriod': "${event.noticePeriod} Days",
        'totalMaxTime': "${event.duration + event.noticePeriod + (event.extensionsEnabled ? event.extensionPeriod : 0)} Days",
        'isFeatured': event.isFeatured,
      };

      await vendors.updateProductSecure(
        vendorId: vendorUid,
        productCode: event.productCode,
        updateData: updateData,
      );

      emit(state.copyWith(
        isSubmitting: false, 
        success: true,
      ));
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


  Future<void> _productsRequested(
    VendorProductsRequested event,
    Emitter<VendorProductsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, currentLimit: 10, hasReachedMax: false, flow: ProductFlow.idle, errorMessage: null, success: false));
    debugPrint('🔹 Fetching products and tab counts...');

    try {
      // 1. Fetch the exact counts cheaply
      final tabCounts = await vendors.fetchProductTabCounts(vendorUid);

      // 2. Update state with the counts immediately so the UI tabs populate
      emit(state.copyWith(statusCounts: tabCounts));

      // 3. Start the stream with just 10 items for pagination
      await _productsStreamSub?.cancel();
      _productsStreamSub = vendors.streamVendorProductItems(vendorUid, limit: state.currentLimit).listen((updatedList) {
        add(VendorProductsUpdated(updatedList, tabCounts)); // Pass the tab counts along
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
    if (state.hasReachedMax) return;

    final newLimit = state.currentLimit + 10;
    emit(state.copyWith(currentLimit: newLimit));

    await _productsStreamSub?.cancel();
    _productsStreamSub = vendors.streamVendorProductItems(vendorUid, limit: newLimit).listen((updatedList) {
      add(VendorProductsUpdated(updatedList, state.statusCounts));
    });
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

    final bool reachedEnd = event.items.length < state.currentLimit;

    //final int targetLength = math.max(state.items.length, 20);

    emit(state.copyWith(
      isSubmitting: false,
      items: event.items,
      statusCounts: event.statusCounts ?? state.statusCounts,
      hasReachedMax: reachedEnd, // Tell the UI to stop showing the loading spinner
    ));
  }

  Future<void> _onDeleteProduct(
    VendorProductsDelete event,
    Emitter<VendorProductsState> emit,
  ) async {
    // 1. Tell the UI we are deleting
    emit(state.copyWith(
      flow: ProductFlow.delete, 
      isSubmitting: true, 
      success: false, 
      errorMessage: null,
    ));

    try {
      await vendors.deleteProductSecure(vendorUid, event.productId, 'single-delete');

      await FirebaseAnalytics.instance.logEvent(
        name: 'product_deleted',
        parameters: {
          'vendor_id': vendorUid,
          'product_id': event.productId,
        },
      );

      final newTabCounts = await vendors.fetchProductTabCounts(vendorUid);
      
      emit(state.copyWith(
        flow: ProductFlow.delete,
        isSubmitting: false,
        success: true,
        statusCounts: newTabCounts, // 🚀 Updates the UI tabs instantly
      ));
    } catch (e) {
      debugPrint("❌ Delete Error: $e");
      // 4. Tell the UI it failed
      emit(state.copyWith(
        flow: ProductFlow.delete,
        isSubmitting: false,
        success: false,
        errorMessage: e.toString().replaceAll("Exception:", "").trim(),
      ));
    }
  }

  void _onToggleSelection(VendorProductsToggleSelection event, Emitter<VendorProductsState> emit) {
    final selected = Set<String>.from(state.selectedIds);
    
    if (selected.contains(event.productId)) {
      selected.remove(event.productId);
    } else {
      selected.add(event.productId);
    }

    // Automatically enter/exit selection mode based on if anything is selected
    emit(state.copyWith(
      selectedIds: selected,
      isSelectionMode: selected.isNotEmpty, 
    ));
  }

  void _onSelectAll(VendorProductsSelectAll event, Emitter<VendorProductsState> emit) {
    final allIds = state.visibleItems.map((p) => p.id).toSet();
    emit(state.copyWith(selectedIds: allIds, isSelectionMode: true));
  }

  void _onClearSelection(VendorProductsClearSelection event, Emitter<VendorProductsState> emit) {
    emit(state.copyWith(selectedIds: const {}, isSelectionMode: false));
  }

  Future<void> _onDeleteMultiple(VendorProductsDeleteMultiple event, Emitter<VendorProductsState> emit) async {
    if (state.selectedIds.isEmpty) return;

    emit(state.copyWith(flow: ProductFlow.delete, isSubmitting: true, success: false, errorMessage: ""));

    try {
      // 🚀 Call repo with a LIST of IDs (We will create this next)
      await vendors.deleteMultipleProductsSecure(vendorUid, state.selectedIds.toList());
      
      await FirebaseAnalytics.instance.logEvent(
        name: 'products_deleted_bulk',
        parameters: {
          'vendor_id': vendorUid,
          'count': state.selectedIds.length,
        },
      );

      final newTabCounts = await vendors.fetchProductTabCounts(vendorUid);
      
      emit(state.copyWith(
        flow: ProductFlow.delete,
        isSubmitting: false,
        success: true,
        statusCounts: newTabCounts,
        selectedIds: const {}, // Clear selection after delete!
        isSelectionMode: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        flow: ProductFlow.delete,
        isSubmitting: false,
        success: false,
        selectedIds: const {},
        isSelectionMode: false,
        errorMessage: e.toString().replaceAll("Exception:", "").trim(),
      ));
    }
  }
}