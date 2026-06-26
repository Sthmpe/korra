import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/reservation.dart'; 

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

// =========================================================
// ✅ NEW BULK EVENTS
// =========================================================

class ResMarkFulfilled extends ReservationsEvent {
  final List<String> planIds;
  const ResMarkFulfilled(this.planIds);
  @override
  List<Object?> get props => [planIds];
}

class ResToggleSelection extends ReservationsEvent {
  final String id;
  const ResToggleSelection(this.id);
  @override
  List<Object?> get props => [id];
}

class ResClearSelection extends ReservationsEvent {}

class ResSelectAll extends ReservationsEvent {
  final List<String> allIds;
  const ResSelectAll(this.allIds);
  @override
  List<Object?> get props => [allIds];
}