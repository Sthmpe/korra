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

  const PlanCreationRequested({
    required this.productCode,
    required this.downPayment,
    required this.autoCommit,
  });

  @override
  List<Object?> get props => [productCode, downPayment, autoCommit];
}
