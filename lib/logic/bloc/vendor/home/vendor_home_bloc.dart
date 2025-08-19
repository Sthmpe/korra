import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'vendor_home_event.dart';
import 'vendor_home_state.dart';

class VendorHomeBloc extends Bloc<VendorHomeEvent, VendorHomeState> {
  VendorHomeBloc() : super(VendorHomeState.mock()) {
    on<VendorHomeStarted>((e, emit) => emit(state));

    on<VendorHomeRefresh>((e, emit) async {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state); // TODO: load from repo
    });

    on<StartPayout>((e, emit) {
      // TODO route to payout flow
      Get.snackbar('Payout', 'Starting payout…', snackPosition: SnackPosition.BOTTOM);
    });

    on<ManagePayoutMethod>((e, emit) {
      // TODO route to payout method manager
      Get.snackbar('Payout method', 'Manage payout method', snackPosition: SnackPosition.BOTTOM);
    });

    on<ViewHoldSchedule>((e, emit) {
      // TODO open hold schedule sheet
      Get.snackbar('On-hold', 'Opening schedule…', snackPosition: SnackPosition.BOTTOM);
    });

    on<OpenReservations>((e, emit) {
      // TODO route to reservations with filter
      Get.snackbar('Reservations', 'Filter: ${e.filter.name}', snackPosition: SnackPosition.BOTTOM);
    });

    on<OpenReservationDetail>((e, emit) {
      // TODO route to reservation detail
      Get.snackbar('Reservation', 'Open ${e.reservationId}', snackPosition: SnackPosition.BOTTOM);
    });

    on<AdjustStockFor>((e, emit) {
      // TODO open stock sheet for product
      Get.snackbar('Product', 'Adjust stock for ${e.productId}', snackPosition: SnackPosition.BOTTOM);
    });

    on<OpenPlanFor>((e, emit) {
      // TODO open plan detail
      Get.snackbar('Plan', 'Open ${e.refId}', snackPosition: SnackPosition.BOTTOM);
    });
  }
}
