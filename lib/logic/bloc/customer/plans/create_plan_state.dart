import 'package:equatable/equatable.dart';

enum CreatePlanStatus { initial, loadingPreview, previewLoaded, creating, success, error }

class CreatePlanState extends Equatable {
  final CreatePlanStatus status;
  final String? errorMessage;
  
  // Data from Supabase Risk Engine
  final double riskEngineUpfront; // The minimum down payment required
  final double loanAmount;        // The amount Korra is lending
  final double gap;               // Any gap payment
  final double dpPercentage;      // The random % generated
  
  const CreatePlanState({
    this.status = CreatePlanStatus.initial,
    this.errorMessage,
    this.riskEngineUpfront = 0.0,
    this.loanAmount = 0.0,
    this.gap = 0.0,
    this.dpPercentage = 0.0,
  });

  CreatePlanState copyWith({
    CreatePlanStatus? status,
    String? errorMessage,
    double? riskEngineUpfront,
    double? loanAmount,
    double? gap,
    double? dpPercentage,
  }) {
    return CreatePlanState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      riskEngineUpfront: riskEngineUpfront ?? this.riskEngineUpfront,
      loanAmount: loanAmount ?? this.loanAmount,
      gap: gap ?? this.gap,
      dpPercentage: dpPercentage ?? this.dpPercentage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, riskEngineUpfront, loanAmount, gap, dpPercentage];
}