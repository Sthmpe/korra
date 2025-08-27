import 'package:equatable/equatable.dart';

enum VendorActivityType { newReservation, paymentMissed, lowStock, info }

class VendorActivity extends Equatable {
  final String id;      // activity id
  final String refId;   // product/reservation/plan id
  final VendorActivityType type;
  final String title;
  final String subtitle;

  const VendorActivity({
    required this.id,
    required this.refId,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  @override
  List<Object?> get props => [id, refId, type, title, subtitle];
}
