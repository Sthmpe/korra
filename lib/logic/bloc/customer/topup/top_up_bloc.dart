import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korra/data/repository/customer/topup_repository.dart';
import 'package:korra/data/repository/customer/wallet_repository.dart';

import '../../../../data/repository/customer/customer_repository.dart';
import 'top_up_event.dart';
import 'top_up_state.dart';

class TopUpBloc extends Bloc<TopUpEvent, TopUpState> {
  final String customerUid;
  final CustomerRepository customers;

  TopUpBloc({required this.customerUid, required this.customers})
    : super(TopUpState.initial()) {
    on<TopUpStarted>(_onStarted);
    on<TopUpRefreshRequested>(_onRefreshRequested);
    on<VerifyPaymentPressed>(_onVerifyPaymentPressed);
  }

  Future<void> _onStarted(TopUpStarted event, Emitter<TopUpState> emit) async {
    emit(state.copyWith(status: TopUpStatus.loading));

    try {
      final details = await customers.getTopUpDetails(customerUid);
      emit(state.copyWith(status: TopUpStatus.loaded, details: details));
    } catch (e) {
      emit(
        state.copyWith(status: TopUpStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRefreshRequested(
    TopUpRefreshRequested event,
    Emitter<TopUpState> emit,
  ) async {
    emit(state.copyWith(status: TopUpStatus.loading));

    try {
      final details = await customers.getTopUpDetails(customerUid);
      emit(state.copyWith(status: TopUpStatus.loaded, details: details));
    } catch (e) {
      emit(
        state.copyWith(status: TopUpStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onVerifyPaymentPressed(
    VerifyPaymentPressed event,
    Emitter<TopUpState> emit,
  ) async {
    emit(state.copyWith(status: TopUpStatus.verifying));

    try {
      // 1. Check Monnify balance
      final balance = await customers.getWalletBalance(
        state.details.walletAccountNumber,
      );

      // 2. Update Firestore (so other devices reflect new balance)
      await customers.updateAvailableBalance(
        customerUid,
        state.details.walletAccountNumber,
      );

      // 3. Emit refreshed state
      final updatedDetails = state.details.copyWith(availableBalance: balance);

      emit(state.copyWith(status: TopUpStatus.loaded, details: updatedDetails));
    } catch (e) {
      emit(
        state.copyWith(status: TopUpStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
