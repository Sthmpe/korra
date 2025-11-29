import 'package:equatable/equatable.dart';

abstract class LinkEvent extends Equatable {
  const LinkEvent();

  @override
  List<Object?> get props => [];
}

class LinkSubmitted extends LinkEvent {
  final String value;
  const LinkSubmitted(this.value);

  @override
  List<Object?> get props => [value];
}

class LinkValidated extends LinkEvent {
  final String productCode;
  const LinkValidated(this.productCode);

  @override
  List<Object?> get props => [productCode];
}

class PlanCreationRequested extends LinkEvent {
  final String productCode;
  final double downPayment;
  final bool autoCommit;
  final String cadenceType;
  final int durationMonths;
  final double amountPerPeriod;

  const PlanCreationRequested({
    required this.productCode,
    required this.downPayment,
    required this.autoCommit,
    required this.cadenceType,
    required this.durationMonths,
    required this.amountPerPeriod,
  });

  @override
  List<Object?> get props => [productCode, downPayment, autoCommit, cadenceType, durationMonths, amountPerPeriod];
}
