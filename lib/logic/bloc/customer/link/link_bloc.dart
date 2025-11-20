import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/models/customer/plans.dart';
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
    on<PlanCreationRequested>(_onPlanCreationRequested);
  }

  /// STEP 1: User pastes link
  Future<void> _onLinkSubmitted(LinkSubmitted e, Emitter<LinkState> emit) async {
    emit(state.copyWith(status: LinkStatus.validating, message: "Validating link"));

    final korraRegex = RegExp(r'^korra-[A-Z0-9]{4}-[a-f0-9]{7}$');


    if (!korraRegex.hasMatch(e.value)) {
      emit(state.copyWith(
        status: LinkStatus.invalid,
        message: "Invalid link format",
      ));
      return;
    }

    emit(state.copyWith(
      status: LinkStatus.valid,
      message: "Link valid",
    ));

    add(LinkValidated(e.value));
  }

  /// STEP 2: Validate link → get product
  Future<void> _onLinkValidated(
      LinkValidated e, Emitter<LinkState> emit) async {
    emit(state.copyWith(status: LinkStatus.loadingProduct, message: "Fetching product"));

    try {
      final productFetch = await customerRepo.getProduct(e.productCode);

      emit(state.copyWith(
        status: LinkStatus.loaded,
        message: "Product fetched",
        productFetch: productFetch,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: LinkStatus.failure,
        message: "Failed to fetch product",
      ));
    }
  }

  /// STEP 3: Confirm → Create plan
  Future<void> _onPlanCreationRequested(
      PlanCreationRequested e, Emitter<LinkState> emit) async {
    emit(state.copyWith(status: LinkStatus.creating, message: "Creating plan"));

    try {
      /// Call your full plan creation process
      final plan = await customerRepo.createPlan(
        productCode: e.productCode,
        downPayment: e.downPayment,
        customerId: customerUid,
        commitmentEnabled: e.autoCommit,
        productFeteched: state.productFetch!,
      );

      emit(state.copyWith(
        status: LinkStatus.success,
        plan: plan,
      ));
    } catch (err) {
      emit(state.copyWith(
        status: LinkStatus.failure,
        message: err.toString(),
      ));
    }
  }
}
