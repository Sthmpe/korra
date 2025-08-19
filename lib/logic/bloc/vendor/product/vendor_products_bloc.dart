import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../../../presentation/vendor/product/widgets/share_link_sheet.dart';
import 'vendor_products_event.dart';
import 'vendor_products_state.dart';


class VendorProductsBloc extends Bloc<VendorProductsEvent, VendorProductsState> {
  VendorProductsBloc() : super(VendorProductsState.mock()) {
    on<VendorProductsStarted>((e, emit) => emit(state));

    on<VendorProductsRefresh>((e, emit) async {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state); // TODO pull from repository
    });

    on<VendorProductsQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<VendorProductsFilterChanged>((e, emit) => emit(state.copyWith(filter: e.filter)));

    on<VendorProductsCreatePressed>((e, emit) {
      // TODO: open create-product flow
      Get.snackbar('Create', 'Open create product', snackPosition: SnackPosition.BOTTOM);
    });

    on<VendorProductsSharePressed>((e, emit) async {
      final p = state.items.firstWhere((x) => x.id == e.productId);
      if (!p.shareable) {
        Get.snackbar('Unavailable', 'Link will be available after approval and if in stock.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await ShareLinkSheet.show(Get.context!, productName: p.name, token: 'PR-${p.id}-X8Z4');
    });

    on<VendorProductsEditPressed>((e, emit) {
      // TODO edit flow
      Get.snackbar('Edit', 'Edit ${e.productId}', snackPosition: SnackPosition.BOTTOM);
    });

    on<VendorProductsRestockPressed>((e, emit) {
      // TODO restock flow
      Get.snackbar('Restock', 'Restock ${e.productId}', snackPosition: SnackPosition.BOTTOM);
    });
  }
}
