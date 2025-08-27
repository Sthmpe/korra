import 'package:equatable/equatable.dart';

import '../../../../data/models/vendor/vendor_reservation.dart';

abstract class VendorReservationsEvent extends Equatable {
  const VendorReservationsEvent();
  @override
  List<Object?> get props => [];
}

class VResStarted extends VendorReservationsEvent {
  final ReservationStatus initial;
  const VResStarted(this.initial);
}

class VResChangeFilter extends VendorReservationsEvent {
  final ReservationStatus filter;
  const VResChangeFilter(this.filter);
}

class VResSearchChanged extends VendorReservationsEvent {
  final String query;
  const VResSearchChanged(this.query);
}

class VResRefresh extends VendorReservationsEvent { const VResRefresh(); }

class VResOpen extends VendorReservationsEvent { final String id; const VResOpen(this.id); }
class VResArrangeDelivery extends VendorReservationsEvent { final String id; const VResArrangeDelivery(this.id); }
