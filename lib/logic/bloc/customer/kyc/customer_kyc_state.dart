import 'package:equatable/equatable.dart';

class CustomerKycState extends Equatable {
  // BVN Fields
  final String bvnInput;
  final bool isBvnVerified;
  final bool bvnVerificationInProgress;
  final String? bvnVerificationError;

  // NIN Fields
  final String ninInput;
  final bool isNinVerified;
  final bool ninVerificationInProgress;
  final String? ninVerificationError;

  // Personal Info Fields
  final String? gender;
  final DateTime? dob;
  final String phone;
  final bool isEditingPhone;
  final bool isUpdatingPhone;

  const CustomerKycState({
    this.bvnInput = '',
    this.isBvnVerified = false,
    this.bvnVerificationInProgress = false,
    this.bvnVerificationError,
    
    this.ninInput = '',
    this.isNinVerified = false,
    this.ninVerificationInProgress = false,
    this.ninVerificationError,
    
    this.gender,
    this.dob,
    this.phone = '',
    this.isEditingPhone = false,
    this.isUpdatingPhone = false,
  });

  CustomerKycState copyWith({
    String? bvnInput,
    bool? isBvnVerified,
    bool? bvnVerificationInProgress,
    String? bvnVerificationError,
    
    String? ninInput,
    bool? isNinVerified,
    bool? ninVerificationInProgress,
    String? ninVerificationError,
    
    String? gender,
    DateTime? dob,
    String? phone,
    bool? isEditingPhone,
    bool? isUpdatingPhone,
    
    // Hack to allow nulling out errors
    bool clearBvnError = false,
    bool clearNinError = false,
  }) {
    return CustomerKycState(
      bvnInput: bvnInput ?? this.bvnInput,
      isBvnVerified: isBvnVerified ?? this.isBvnVerified,
      bvnVerificationInProgress: bvnVerificationInProgress ?? this.bvnVerificationInProgress,
      bvnVerificationError: clearBvnError ? null : (bvnVerificationError ?? this.bvnVerificationError),
      
      ninInput: ninInput ?? this.ninInput,
      isNinVerified: isNinVerified ?? this.isNinVerified,
      ninVerificationInProgress: ninVerificationInProgress ?? this.ninVerificationInProgress,
      ninVerificationError: clearNinError ? null : (ninVerificationError ?? this.ninVerificationError),
      
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      isEditingPhone: isEditingPhone ?? this.isEditingPhone,
      isUpdatingPhone: isUpdatingPhone ?? this.isUpdatingPhone,
    );
  }

  @override
  List<Object?> get props => [
        bvnInput, isBvnVerified, bvnVerificationInProgress, bvnVerificationError,
        ninInput, isNinVerified, ninVerificationInProgress, ninVerificationError,
        gender, dob, phone, isEditingPhone, isUpdatingPhone,
      ];
}
