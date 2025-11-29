import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repository/customer/customer_repository.dart';
import '../../../core/net/net_cubit.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CustomerRepository customerRepo;
  final String customerUid;
  final NetCubit net;
  HomeBloc({
    required this.customerRepo,
    required this.customerUid,
    required this.net,
  }) : super(HomeState.initial()) {
    on<PasteLinkSubmitted>(_onPaste);
    on<WalletBalanceUpdated>(_onWalletBalanceUpdated);
    on<HomeStarted>(_onStarted);
  }

  void _onWalletBalanceUpdated(
    WalletBalanceUpdated event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(walletBalance: event.balance.toString()));
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    // Your logic to load vendors, etc.
    // Example:
    emit(state.copyWith(status: HomeStatus.loading));
    try {
       // Load data...
       // emit(state.copyWith(status: HomeStatus.success, ...));
    } catch (e) {
       // emit(state.copyWith(status: HomeStatus.failure));
    }
  }
  
  Future<void> _onPaste(PasteLinkSubmitted e, Emitter<HomeState> emit) async {
    // For MVP just show a toast message via message field
    emit(state.copyWith(message: 'Link received: ${e.value}'));
    // In real flow: validate → open quote screen
  }
}
