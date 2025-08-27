import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/customer/user_profile.dart';
import '../../../../data/repository/customer/profile_repository.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repo;
  UserProfile? _profile; // typed model internally

  ProfileBloc(this.repo) : super(const ProfileState()) {
    on<ProfileStarted>(_onLoad);
    on<ProfileRefreshed>(_onLoad);

    on<ToggleAutopayDefault>(_onToggleAutopay);
    on<ToggleBiometrics>(_onToggleBiometrics);

    on<TogglePushNotif>(_onTogglePush);
    on<ToggleEmailNotif>(_onToggleEmail);
    on<ToggleSmsNotif>(_onToggleSms);

    on<ChangeReminderCadence>(_onChangeCadence);

    on<LogoutRequested>(_onLogout);
    on<DeleteAccountRequested>(_onDelete);
  }

  void _pushToState(UserProfile p, Emitter<ProfileState> emit) {
    emit(state.copyWith(
      status: ProfileStatus.ready,
      error: null,
      name: p.name,
      email: p.email,
      phone: p.phone,
      initials: p.initials,
      kycVerified: p.kycVerified,
      basicTier: p.basicTier,
      walletBalanceText: p.walletBalanceText,
      defaultMethodMasked: p.defaultMethodMasked,
      autopayDefault: p.autopayDefault,
      pushNotif: p.pushNotif,
      emailNotif: p.emailNotif,
      smsNotif: p.smsNotif,
      reminderCadence: p.reminderCadence,
      biometricsEnabled: p.biometricsEnabled,
    ));
  }

  Future<void> _onLoad(ProfileEvent e, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading, error: null, message: null));
    try {
      _profile = await repo.fetchProfile();
      _pushToState(_profile!, emit);
    } catch (err) {
      emit(state.copyWith(status: ProfileStatus.error, error: '$err'));
    }
  }

  Future<void> _onToggleAutopay(ToggleAutopayDefault e, Emitter<ProfileState> emit) async {
    if (_profile == null) return;
    emit(state.copyWith(updatingAutopay: true));
    _profile = await repo.toggleAutopayDefault(_profile!, e.value);
    _pushToState(_profile!, emit);
    emit(state.copyWith(updatingAutopay: false, message: e.value ? 'AutoPay enabled' : 'AutoPay disabled'));
  }

  Future<void> _onToggleBiometrics(ToggleBiometrics e, Emitter<ProfileState> emit) async {
    if (_profile == null) return;
    emit(state.copyWith(updatingBiometrics: true));
    _profile = await repo.toggleBiometrics(_profile!, e.value);
    _pushToState(_profile!, emit);
    emit(state.copyWith(updatingBiometrics: false));
  }

  Future<void> _onTogglePush(TogglePushNotif e, Emitter<ProfileState> emit) async {
    if (_profile == null) return;
    emit(state.copyWith(updatingNotif: true));
    _profile = await repo.toggleNotif(_profile!, push: e.value);
    _pushToState(_profile!, emit);
    emit(state.copyWith(updatingNotif: false));
  }

  Future<void> _onToggleEmail(ToggleEmailNotif e, Emitter<ProfileState> emit) async {
    if (_profile == null) return;
    emit(state.copyWith(updatingNotif: true));
    _profile = await repo.toggleNotif(_profile!, email: e.value);
    _pushToState(_profile!, emit);
    emit(state.copyWith(updatingNotif: false));
  }

  Future<void> _onToggleSms(ToggleSmsNotif e, Emitter<ProfileState> emit) async {
    if (_profile == null) return;
    emit(state.copyWith(updatingNotif: true));
    _profile = await repo.toggleNotif(_profile!, sms: e.value);
    _pushToState(_profile!, emit);
    emit(state.copyWith(updatingNotif: false));
  }

  Future<void> _onChangeCadence(ChangeReminderCadence e, Emitter<ProfileState> emit) async {
    if (_profile == null) return;
    emit(state.copyWith(updatingReminder: true));
    _profile = await repo.changeReminderCadence(_profile!, e.value);
    _pushToState(_profile!, emit);
    emit(state.copyWith(updatingReminder: false));
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<ProfileState> emit) async {
    await repo.logout();
    emit(state.copyWith(message: 'Logged out'));
  }

  Future<void> _onDelete(DeleteAccountRequested e, Emitter<ProfileState> emit) async {
    await repo.deleteAccount();
    emit(state.copyWith(message: 'Account deleted'));
  }
}
