import 'package:equatable/equatable.dart';

enum CreatePlanStatus { initial, loadingPreview, previewLoaded, creating, success, error }

class CreatePlanState extends Equatable {
  final CreatePlanStatus status;
  final String? errorMessage;
  final bool hasActivePlans;
  
  // Data from Supabase Risk Engine
  final double riskEngineUpfront; 
  final double loanAmount;        
  final double gap;               
  final double dpPercentage;      
  
  // ✅ NEW: Tier Config (Calculated locally)
  final int baseDurationDays;   
  final int noticeDays;         
  final int extensionDays;      
  final bool canExtend;     

  // 🔐 Security
  final String? secureToken; // Holds the JWT    

  const CreatePlanState({
    this.status = CreatePlanStatus.initial,
    this.hasActivePlans = false,
    this.errorMessage,
    this.riskEngineUpfront = 0.0,
    this.loanAmount = 0.0,
    this.gap = 0.0,
    this.dpPercentage = 0.0,
    // Defaults
    this.baseDurationDays = 90,
    this.noticeDays = 10,
    this.extensionDays = 30,
    this.canExtend = true,
    this.secureToken,
  });

  CreatePlanState copyWith({
    CreatePlanStatus? status,
    bool? hasActivePlans,
    String? errorMessage,
    double? riskEngineUpfront,
    double? loanAmount,
    double? gap,
    double? dpPercentage,
    int? baseDurationDays,
    int? noticeDays,
    int? extensionDays,
    bool? canExtend,
    String? secureToken,
  }) {
    return CreatePlanState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      hasActivePlans: hasActivePlans ?? this.hasActivePlans,
      riskEngineUpfront: riskEngineUpfront ?? this.riskEngineUpfront,
      loanAmount: loanAmount ?? this.loanAmount,
      gap: gap ?? this.gap,
      dpPercentage: dpPercentage ?? this.dpPercentage,
      baseDurationDays: baseDurationDays ?? this.baseDurationDays,
      noticeDays: noticeDays ?? this.noticeDays,
      extensionDays: extensionDays ?? this.extensionDays,
      canExtend: canExtend ?? this.canExtend,
      secureToken: secureToken ?? this.secureToken,
    );
  }

  @override
  List<Object?> get props => [
    status, hasActivePlans,errorMessage, riskEngineUpfront, loanAmount, gap, dpPercentage,
    baseDurationDays, noticeDays, extensionDays, canExtend, secureToken
  ];
}