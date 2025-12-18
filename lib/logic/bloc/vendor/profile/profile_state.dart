import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, success, failure, logout }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? errorMessage;
  final String? message; // For Toasts (e.g. "Reminder updated")

  // Identity Data (Read Only)
  final String name;
  final String email;
  final String phone;
  final String initials;
  final bool kycVerified;
  final bool basicTier;
  final String walletBalanceText; // We keep this as it might be dynamic

  // Active Preferences (Mutable)
  final String reminderCadence;
  final bool updatingReminder; // Specific loader for the one active feature

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.message,
    
    this.name = '',
    this.email = '',
    this.phone = '',
    this.initials = '',
    this.kycVerified = true,
    this.basicTier = true,
    this.walletBalanceText = '₦0.00',
    
    this.reminderCadence = 'Same day',
    this.updatingReminder = false,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? errorMessage,
    String? message,
    
    String? name,
    String? email,
    String? phone,
    String? initials,
    bool? kycVerified,
    bool? basicTier,
    String? walletBalanceText,
    
    String? reminderCadence,
    bool? updatingReminder,
  }) {
    return ProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage, // Reset error on new state usually
      message: message, // Allow clearing message
      
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      initials: initials ?? this.initials,
      kycVerified: kycVerified ?? this.kycVerified,
      basicTier: basicTier ?? this.basicTier,
      walletBalanceText: walletBalanceText ?? this.walletBalanceText,
      
      reminderCadence: reminderCadence ?? this.reminderCadence,
      updatingReminder: updatingReminder ?? this.updatingReminder,
    );
  }

  @override
  List<Object?> get props => [
    status, errorMessage, message,
    name, email, phone, initials, kycVerified, basicTier, walletBalanceText,
    reminderCadence, updatingReminder,
  ];
}