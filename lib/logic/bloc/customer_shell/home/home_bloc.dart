import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repository/customer/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repo;
  HomeBloc(this.repo) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<PasteLinkSubmitted>(_onPaste);
  }

  Future<void> _onStarted(HomeStarted e, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final results = await Future.wait([
        repo.fetchWalletBalance(),
        repo.fetchDefaultMethodMasked(),
        repo.fetchPlans(),
        repo.fetchSavedVendors(),
        repo.fetchActivity(),
      ]);
      emit(state.copyWith(
        status: HomeStatus.loaded,
        walletBalance: results[0] as String,
        defaultMethodMasked: results[1] as String,
        plans: results[2] as dynamic,
        vendors: results[3] as dynamic,
        activity: results[4] as dynamic,
      ));
    } catch (_) {
      emit(state.copyWith(status: HomeStatus.failure, message: 'Something went wrong.'));
    }
  }

  Future<void> _onPaste(PasteLinkSubmitted e, Emitter<HomeState> emit) async {
    // For MVP just show a toast message via message field
    emit(state.copyWith(message: 'Link received: ${e.value}'));
    // In real flow: validate → open quote screen
  }
}
