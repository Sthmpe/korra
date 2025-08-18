import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, ready, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? error;
  final String? message;

  // Identity (primitives for UI)
  final String name;
  final String email;
  final String phone;
  final String initials;
  final bool kycVerified;   // true
  final bool basicTier;     // true

  // Wallet / Payment
  final String walletBalanceText;
  final String defaultMethodMasked;
  final bool autopayDefault;

  // Preferences
  final bool pushNotif;
  final bool emailNotif;
  final bool smsNotif;
  final String reminderCadence;

  // Security
  final bool biometricsEnabled;

  // Fine-grained updating flags
  final bool updatingAutopay;
  final bool updatingBiometrics;
  final bool updatingNotif;
  final bool updatingReminder;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.error,
    this.message,

    this.name = '',
    this.email = '',
    this.phone = '',
    this.initials = '',
    this.kycVerified = true,
    this.basicTier = true,

    this.walletBalanceText = '',
    this.defaultMethodMasked = '',
    this.autopayDefault = false,

    this.pushNotif = true,
    this.emailNotif = false,
    this.smsNotif = true,
    this.reminderCadence = '1 day before',

    this.biometricsEnabled = false,

    this.updatingAutopay = false,
    this.updatingBiometrics = false,
    this.updatingNotif = false,
    this.updatingReminder = false,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? error,
    String? message,

    String? name,
    String? email,
    String? phone,
    String? initials,
    bool? kycVerified,
    bool? basicTier,

    String? walletBalanceText,
    String? defaultMethodMasked,
    bool? autopayDefault,

    bool? pushNotif,
    bool? emailNotif,
    bool? smsNotif,
    String? reminderCadence,

    bool? biometricsEnabled,

    bool? updatingAutopay,
    bool? updatingBiometrics,
    bool? updatingNotif,
    bool? updatingReminder,
  }) {
    return ProfileState(
      status: status ?? this.status,
      error: error,
      message: message,

      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      initials: initials ?? this.initials,
      kycVerified: kycVerified ?? this.kycVerified,
      basicTier: basicTier ?? this.basicTier,

      walletBalanceText: walletBalanceText ?? this.walletBalanceText,
      defaultMethodMasked: defaultMethodMasked ?? this.defaultMethodMasked,
      autopayDefault: autopayDefault ?? this.autopayDefault,

      pushNotif: pushNotif ?? this.pushNotif,
      emailNotif: emailNotif ?? this.emailNotif,
      smsNotif: smsNotif ?? this.smsNotif,
      reminderCadence: reminderCadence ?? this.reminderCadence,

      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,

      updatingAutopay: updatingAutopay ?? this.updatingAutopay,
      updatingBiometrics: updatingBiometrics ?? this.updatingBiometrics,
      updatingNotif: updatingNotif ?? this.updatingNotif,
      updatingReminder: updatingReminder ?? this.updatingReminder,
    );
  }

  @override
  List<Object?> get props => [
    status, error, message,
    name, email, phone, initials, kycVerified, basicTier,
    walletBalanceText, defaultMethodMasked, autopayDefault,
    pushNotif, emailNotif, smsNotif, reminderCadence,
    biometricsEnabled,
    updatingAutopay, updatingBiometrics, updatingNotif, updatingReminder,
  ];
}
