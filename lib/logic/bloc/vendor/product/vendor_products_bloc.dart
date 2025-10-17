import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/product_model.dart';
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
  void _onStarted(
    VendorProductsStarted event,
    Emitter<VendorProductsState> emit,
  ) {
    emit(state);
    add(VendorProductsRequested());
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
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    debugPrint('Adding product...');

    try {
      // 1️⃣ Validate Images with AI
      final validation = await vendors.validateProductImagesWithAI(
        event.images,
        description: event.description,
        category: event.category,
      );

      if (!validation.success) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: validation.errorMessages.join("\n"),
          ),
        );
        return;
      }

      // 2️⃣ Validate Price
      final isPriceValid = await vendors.validateProductPrice(
        event.category,
        event.price.toInt(),
      );

      if (!isPriceValid) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage:
                "Product reservation price is beyond the acceptable range.",
          ),
        );
        return;
      }

      // 3️⃣ Check vendor limit
      final vendorLimit = await vendors.getVendorLimit(vendorUid);

      if (vendorLimit != null) {
        final limit = (vendorLimit['reservationLimit'] ?? 0).toInt();
        final used = (vendorLimit['currentUsedAmount'] ?? 0).toInt();
        final remaining = limit - used;
        final totalValue = event.price.toInt() * event.stock;

        if (totalValue > remaining) {
          emit(
            state.copyWith(
              isSubmitting: false,
              errorMessage:
                  "Adding this product exceeds your reservation limit of ₦${NumberFormat('#,##0', 'en_US').format(remaining)}. Please contact support.",
            ),
          );
          return;
        }

        // 4️⃣ Upload Images
        final uploadedUrls = await vendors.uploadProductImagesToCloud(
          event.images,
        );

        if (uploadedUrls.isEmpty) {
          emit(
            state.copyWith(
              isSubmitting: false,
              errorMessage: "Failed to upload images.",
            ),
          );
          return;
        }

        // Generate product ID + code
        final newProduct = Product.create(
          vendorId: vendorUid,
          name: event.name,
          description: event.description,
          price: event.price,
          stock: event.stock,
          category: event.category,
          images: uploadedUrls,
          status: ProductStatus.approved,
        );

        // Save to Firestore
        await vendors.addProduct(newProduct);

        await vendors.updateVendorUsedAmount(
          vendorUid,
          amount: totalValue.toDouble(),
          increase: true,
        );
      } else {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: "Failed to fetch vendor limits. Try again later.",
          ),
        );
        return;
      }

      // // Fetch the latest list of products from Firestore
      // final fetchedProducts = await vendors.fetchProductsByVendor(vendorUid);

      // // Convert them to ProductItem list for state
      // final updatedItems = fetchedProducts.map((p) {
      //   return ProductItem(
      //     id: p.id,
      //     name: p.name,
      //     code: p.code,
      //     description: p.description,
      //     category: p.category,
      //     priceText: '₦${p.price.toStringAsFixed(0)}',
      //     stock: p.availableStock,
      //     status: p.status,
      //     imageUrl: p.images.isNotEmpty ? [p.images.first] : [],
      //     createdAt: p.createdAt,
      //   );
      // }).toList();

      emit(
        state.copyWith(
          // items: updatedItems, 
          isSubmitting: false, 
          success: true
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          isSubmitting: false,
          success: false,
          errorMessage: err.toString(),
        ),
      );
    }
  }

Future<void> _onEditProduct(
  VendorProductsEdit event,
  Emitter<VendorProductsState> emit,
) async {
  emit(state.copyWith(isSubmitting: true, errorMessage: null));

  try {
    // 1️⃣ Get product record
    final product = await vendors.fetchSingleProduct(vendorUid, event.productCode);
    if (product == null) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: "Product not found.",
      ));
      return;
    }

    // 2️⃣ If rejected — full revalidation
    List<String> finalImageUrls = event.existingImageUrls;
    debugPrint("🔄 Editing product ${event.status}...");
    if (event.status == ProductStatus.rejected) {
      debugPrint("newImages: ${event.newImages.length}");
      debugPrint("🔄 Product was rejected, performing full revalidation...");
      if (event.newImages.isNotEmpty) {
        debugPrint("🔄 New images provided, validating with AI...");
        // ✅ Validate new images with AI
        final validation = await vendors.validateProductImagesWithAI(
          event.newImages,
          description: event.description,
          category: event.category,
        );

        if (!validation.success) {
          emit(state.copyWith(
            isSubmitting: false,
            errorMessage: validation.errorMessages.join("\n"),
          ));
          return;
        }
      }

      // ✅ Validate price again
      final isPriceValid = await vendors.validateProductPrice(
        event.category,
        event.price.toInt(),
      );

      if (!isPriceValid) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage:
              "Product reservation price is beyond the acceptable range.",
        ));
        return;
      }

      if (event.newImages.isNotEmpty) {
        // ✅ Upload new images
        final uploadedUrls = await vendors.uploadProductImagesToCloud(
          event.newImages,
        );

        if (uploadedUrls.isEmpty) {
          emit(state.copyWith(
            isSubmitting: false,
            errorMessage: "Failed to upload new images.",
          ));
          return;
        }

        finalImageUrls = uploadedUrls;        
      }
    }

    // 3️⃣ Check and adjust vendor reserve limit if necessary
    final vendorLimit = await vendors.getVendorLimit(vendorUid);

    if (vendorLimit == null) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: "Failed to fetch vendor limits.",
      ));
      return;
    }

    final limit = (vendorLimit['reservationLimit'] ?? 0).toInt();
    final used = (vendorLimit['currentUsedAmount'] ?? 0).toInt();

    // Vendor’s *already reserved* value for this product
    final oldReservedValue = (product.initialStock - product.availableStock) * product.price;
    final unUsedReserved = (product.initialStock * product.price) - oldReservedValue;

    final adjustedUsed =  used - unUsedReserved;
    final remaining = limit - adjustedUsed;
    final totalValue = event.price.toInt() * event.stock;

    // Only check limit if totalValue increases
    if (totalValue > remaining) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage:
            "Updating this product exceeds your reservation limit of ₦${NumberFormat('#,##0', 'en_US').format(remaining)}.",
      ));
      return;
    }

    // 4️⃣ Update product fields
    final updatedProduct = product.copyWith(
      name: event.name,
      description: event.description,
      category: event.category,
      price: event.price,
      availableStock: event.stock,
      images: finalImageUrls,
      status: ProductStatus.approved,
      updatedAt: DateTime.now(),
    );

    bool productsUpdated = await vendors.updateProduct(
      vendorId: vendorUid,
      productCode: event.productCode,
      updatedProduct: updatedProduct,
    );

    if (!productsUpdated) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: "Failed to update product. Try again.",
      ));
      return;
    }

    // 🧹 Delete old images
    await vendors.deleteProductImages(product.images);

    // 5️⃣ Adjust vendor used amount 
    await vendors.updateVendorUsedAmount(
      vendorUid,
      amount: totalValue.toDouble(),
      newCurrent: adjustedUsed.toDouble() + totalValue.toDouble(),
      increase: false,
    );

    // 6️⃣ Update local state item
    emit(state.copyWith(
      isSubmitting: false,
      success: true,
    ));
  } catch (e) {
    emit(state.copyWith(
      isSubmitting: false,
      errorMessage: e.toString(),
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
