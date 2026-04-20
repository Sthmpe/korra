import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/reservation.dart'; 
// Note: Keeping VendorReservation model name as is, since it describes the data structure.

abstract class ReservationsEvent extends Equatable {
  const ReservationsEvent();
  
  @override
  List<Object?> get props => [];
}

class ResStarted extends ReservationsEvent {
  final ReservationStatus filter;
  const ResStarted(this.filter);
  
  @override
  List<Object?> get props => [filter];
}

class ResRefresh extends ReservationsEvent {
  const ResRefresh();
}

class ResChangeFilter extends ReservationsEvent {
  final ReservationStatus filter;
  const ResChangeFilter(this.filter);
  
  @override
  List<Object?> get props => [filter];
}

class ResLoadMore extends ReservationsEvent {
  const ResLoadMore();
  
  @override
  List<Object> get props => [];
}

class ResVerifyPickup extends ReservationsEvent {
  final String planId;
  final String pin;
  final String customerId;

  const ResVerifyPickup({required this.planId, required this.pin, required this.customerId});

  @override
  List<Object?> get props => [planId, pin, customerId];
}

class ResSearchChanged extends ReservationsEvent {
  final String query;
  const ResSearchChanged(this.query);
  
  @override
  List<Object?> get props => [query];
}

class ResOpen extends ReservationsEvent {
  final String id;
  const ResOpen(this.id);
  
  @override
  List<Object?> get props => [id];
}

class ResArrangeDelivery extends ReservationsEvent {
  final String id;
  const ResArrangeDelivery(this.id);
  
  @override
  List<Object?> get props => [id];
}