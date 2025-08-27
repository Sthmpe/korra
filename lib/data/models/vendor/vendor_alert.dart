import 'package:equatable/equatable.dart';

enum AlertKind { newReservation, missedPayment, lowStock, info }

class VendorAlert extends Equatable {
  final AlertKind kind;
  final String title;
  final String subtitle;

  const VendorAlert({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  @override
  List<Object?> get props => [kind, title, subtitle];
}
