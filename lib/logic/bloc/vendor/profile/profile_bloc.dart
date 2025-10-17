import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../core/net/net_cubit.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final VendorRepository vendors;
  final String vendorUid;
  final NetCubit net;

  ProfileBloc({
    required this.vendors,
    required this.vendorUid,
    required this.net,
  }) : super(ProfileState.initial()) {
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final online = await net.preflight();
    if (!online) return; 

    try {
      await vendors.logout();
      emit(state.copyWith(status: ProfileStatus.logout));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
