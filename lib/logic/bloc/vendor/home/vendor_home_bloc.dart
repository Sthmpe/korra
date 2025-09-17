// lib/logic/bloc/vendor/home/vendor_home_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:korra/data/repository/vendors/payout_repository.dart';

import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../core/net/net_cubit.dart';
import '../../../utils/currency_formatters.dart';
import 'vendor_home_event.dart';
import 'vendor_home_state.dart';

class VendorHomeBloc extends Bloc<VendorHomeEvent, VendorHomeState> {
  final VendorRepository vendors;
  final String vendorUid;
  final NetCubit net;

  VendorHomeBloc({required this.vendors, required this.vendorUid, required this.net})
      // ▼ CHANGE this from .mock() to .initial()
      : super(VendorHomeState.initial()) {
    on<VendorHomeStarted>(_onStarted);
    on<VendorHomeRefresh>(_onRefresh);
    on<ManagePayoutMethod>(_onManagePayoutMethod);
    on<ViewHoldSchedule>(_onViewHoldSchedule);
  }

  Future<void> _onStarted(VendorHomeStarted event, Emitter<VendorHomeState> emit) async {
    await _loadHomeData(emit);
  }

  Future<void> _onRefresh(VendorHomeRefresh event, Emitter<VendorHomeState> emit) async {
    await _loadHomeData(emit);
  }

  Future<void> _loadHomeData(Emitter<VendorHomeState> emit) async {
    final online = await net.preflight();
    if (!online) return; 


    try {
      // ▼ EMIT loading state first
      emit(state.copyWith(status: VendorHomeStatus.loading));

      // Fetch payout details
      final payout = await vendors.getPayoutDetails(vendorUid);


      // On-hold & next release (optional, you can fetch from your system)
      final onHold = '₦1,300,000'; // Replace with real data if available
      final nextRelease = 'Aug 27'; // Replace with real data if available

      // ▼ EMIT success state with the fetched data
      emit(state.copyWith(
        status: VendorHomeStatus.success,
        withdrawable: '₦${formatToCurrency(payout?.withdrawableBalance ?? 0)}',
        payoutMethodMasked: payout?.masked ?? 'Add method',
        withdrawableMinor: payout?.withdrawableBalance.toInt() ?? 0,
        onHold: onHold,
        nextReleaseDate: nextRelease,
        // You would also fetch and update counts and activities here
      ));
    } catch (e) {
      // ▼ EMIT failure state on error
      emit(state.copyWith(status: VendorHomeStatus.failure));
    }
  }

  Future<void> _onManagePayoutMethod(ManagePayoutMethod event, Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(navigateToPayout: true));
  }

  void _onViewHoldSchedule(ViewHoldSchedule event, Emitter<VendorHomeState> emit) {
    Get.snackbar('On-hold', 'Opening schedule…', snackPosition: SnackPosition.BOTTOM);
  }
}