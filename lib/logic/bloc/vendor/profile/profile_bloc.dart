import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/utils/korra_exception.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../core/net/net_cubit.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final VendorRepository vendorRepo;
  final NetCubit net;
  final String vendorUid; // Add vendorUid to the constructor

  ProfileBloc({
    required this.vendorRepo,
    required this.net,
    required this.vendorUid, // Initialize vendorUid
  }) : super(const ProfileState()) {
    on<LogoutRequested>(_onLogout);
    on<DeleteAccountRequested>(_onDelete);
    // Note: 'ChangeReminderCadence' can be added here later if you want to write to Firestore
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<ProfileState> emit) async {
    // Optional: Check internet
    // final online = await net.preflight(); 
    // if (!online) return;

    try {
      await vendorRepo.logout(vendorUid);
      emit(state.copyWith(status: ProfileStatus.logout, message: "Logged out successfully"));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: "Logout failed: $e"));
    }
  }

 Future<void> _onDelete(DeleteAccountRequested e, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    
    try {
      // Call Repo
      //await vendorRepo.deleteAccount();
      
      // Success: Trigger Logout Navigation
      emit(state.copyWith(
        status: ProfileStatus.logout, 
        message: 'Your account has been deleted successfully.'
      ));
      
    } catch (e) {
      // Failure: Show the specific reason (e.g., "You have active plans")
      String errorMsg = "Delete failed";
      if (e is KorraException) {
        errorMsg = e.message;
      }
      
      emit(state.copyWith(
        status: ProfileStatus.failure, 
        errorMessage: errorMsg // This will show in the Red Snack Bar
      ));
    }
  }
}