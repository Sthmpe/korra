import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/vendor_reservation.dart';

abstract class VendorReservationsEvent extends Equatable {
  const VendorReservationsEvent();
  @override
  List<Object?> get props => [];
}

class VResStarted extends VendorReservationsEvent {
  final ReservationStatus filter; // ✅ Added this property
  const VResStarted(this.filter);
  @override
  List<Object?> get props => [filter];
}

class VResRefresh extends VendorReservationsEvent {
  const VResRefresh();
}

class VResChangeFilter extends VendorReservationsEvent {
  final ReservationStatus filter;
  const VResChangeFilter(this.filter);
  @override
  List<Object?> get props => [filter];
}

class VResSearchChanged extends VendorReservationsEvent {
  final String query;
  const VResSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class VResOpen extends VendorReservationsEvent {
  final String id;
  const VResOpen(this.id);
}

class VResArrangeDelivery extends VendorReservationsEvent {
  final String id;
  const VResArrangeDelivery(this.id);
}