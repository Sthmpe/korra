import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/customer/plans_repository.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import 'link_event.dart';
import 'link_state.dart';

class LinkBloc extends Bloc<LinkEvent, LinkState> {
  final CustomerRepository customerRepo;
  final String customerUid;

  LinkBloc({
    required this.customerRepo,
    required this.customerUid,
  }) : super(const LinkState()) {
    on<LinkSubmitted>(_onLinkSubmitted);
    on<LinkValidated>(_onLinkValidated);
  }

  /// STEP 1: User pastes link
  Future<void> _onLinkSubmitted(LinkSubmitted e, Emitter<LinkState> emit) async {
    emit(state.copyWith(status: LinkStatus.validating, message: "Validating link"));

    final cleanInput = e.value.trim().toUpperCase();

    debugPrint("Validating link: $cleanInput");

    final korraRegex = RegExp(r'^K-[A-Z0-9]{4}-[A-Z0-9]{7}$');

    if (cleanInput.isEmpty) {
      emit(state.copyWith(
        status: LinkStatus.empty,
        message: "Please enter a link",
      ));
      return;
    }


    if (!korraRegex.hasMatch(cleanInput)) {
      emit(state.copyWith(
        status: LinkStatus.invalid,
        message: "Invalid code format. It should look like K-ABCD-1234567",
      ));
      return;
    }

    emit(state.copyWith(
      status: LinkStatus.valid,
      message: "Link valid",
    ));

    add(LinkValidated(cleanInput));
  }

  /// STEP 2: Validate link → get product
  Future<void> _onLinkValidated(
      LinkValidated e, Emitter<LinkState> emit) async {
    emit(state.copyWith(status: LinkStatus.loadingProduct, message: "Fetching product"));

    try {
      final productFetch = await customerRepo.getProduct(e.productCode.trim());

      debugPrint("product fetch result from bloc: $productFetch");

      if (productFetch == null) {
        emit(state.copyWith(
          status: LinkStatus.failed,
          message: "Product not found for code: ${e.productCode.trim()}",
        ));
        return;
      }

      // Outright-only products can't start a plan — the UI redirects the
      // customer to the merchant's storefront instead of create-plan.
      if ((productFetch.data['allowReservation'] ?? true) == false) {
        emit(state.copyWith(
          status: LinkStatus.outrightOnly,
          message: "This product is sold outright only",
          productFetch: productFetch,
        ));
        return;
      }

      emit(state.copyWith(
        status: LinkStatus.loaded,
        message: "Product fetched",
        productFetch: productFetch,
      ));
    } catch (e) {
      debugPrint("❌ Bloc Catch: $e");
      emit(state.copyWith(
        status: LinkStatus.failed,
        message: "Connection error. Please try again.",
      ));
    }
  }
}
