import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VendorProfileState extends Equatable {
  final bool loading;

  // Identity
  final String name;
  final String email;
  final String phone;
  final bool verified;      // green chip
  final String tier;        // e.g. Basic

  // Wallet & payments
  final String walletBalanceText;      // ₦75,500.00
  final String defaultMethodMasked;    // •••• 4242
  final bool autoPay;

  // Preferences
  final bool push;
  final bool emailNotif;
  final bool sms;

  // Reminders
  /// allowed: 0, 1, 3  (days)
  final int reminderDays;

  // Security
  final bool biometric;

  // About
  final String versionText;            // 1.0.0 (42)

  const VendorProfileState({
    this.loading = true,
    this.name = 'Ola N. Ade',
    this.email = 'ola@example.com',
    this.phone = '09152540533',
    this.verified = true,
    this.tier = 'Basic',
    this.walletBalanceText = '₦75,500.00',
    this.defaultMethodMasked = '•••• 4242',
    this.autoPay = false,
    this.push = true,
    this.emailNotif = false,
    this.sms = true,
    this.reminderDays = 1,
    this.biometric = false,
    this.versionText = '1.0.0 (42)',
  });

  VendorProfileState copyWith({
    bool? loading,
    String? name,
    String? email,
    String? phone,
    bool? verified,
    String? tier,
    String? walletBalanceText,
    String? defaultMethodMasked,
    bool? autoPay,
    bool? push,
    bool? emailNotif,
    bool? sms,
    int? reminderDays,
    bool? biometric,
    String? versionText,
  }) {
    return VendorProfileState(
      loading: loading ?? this.loading,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      verified: verified ?? this.verified,
      tier: tier ?? this.tier,
      walletBalanceText: walletBalanceText ?? this.walletBalanceText,
      defaultMethodMasked: defaultMethodMasked ?? this.defaultMethodMasked,
      autoPay: autoPay ?? this.autoPay,
      push: push ?? this.push,
      emailNotif: emailNotif ?? this.emailNotif,
      sms: sms ?? this.sms,
      reminderDays: reminderDays ?? this.reminderDays,
      biometric: biometric ?? this.biometric,
      versionText: versionText ?? this.versionText,
    );
  }

  @override
  List<Object?> get props => [
        loading, name, email, phone, verified, tier,
        walletBalanceText, defaultMethodMasked, autoPay,
        push, emailNotif, sms, reminderDays, biometric, versionText
      ];
}

class VendorProfileCubit extends Cubit<VendorProfileState> {
  VendorProfileCubit() : super(const VendorProfileState());

  Future<void> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    emit(state.copyWith(loading: false));
  }

  void toggleAutoPay(bool v) => emit(state.copyWith(autoPay: v));
  void togglePush(bool v)    => emit(state.copyWith(push: v));
  void toggleEmail(bool v)   => emit(state.copyWith(emailNotif: v));
  void toggleSms(bool v)     => emit(state.copyWith(sms: v));
  void toggleBio(bool v)     => emit(state.copyWith(biometric: v));
  void setReminder(int d)    => emit(state.copyWith(reminderDays: d));
}
