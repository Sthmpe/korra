import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/vendor_reservation.dart';

class VendorReservationsState extends Equatable {
  final bool loading;
  final ReservationStatus filter;
  final String query;
  final List<VendorReservation> all;      // source of truth
  final List<VendorReservation> visible;  // filtered for UI
  final String countNew, countOngoing, countCompleted, countCancelled;

  const VendorReservationsState({
    required this.loading,
    required this.filter,
    required this.query,
    required this.all,
    required this.visible,
    required this.countNew,
    required this.countOngoing,
    required this.countCompleted,
    required this.countCancelled,
  });

  factory VendorReservationsState.initial(ReservationStatus f) => VendorReservationsState(
    loading: true, filter: f, query: '',
    all: const [], visible: const [],
    countNew: '0', countOngoing: '0', countCompleted: '0', countCancelled: '0',
  );

  VendorReservationsState copyWith({
    bool? loading,
    ReservationStatus? filter,
    String? query,
    List<VendorReservation>? all,
    List<VendorReservation>? visible,
    String? countNew,
    String? countOngoing,
    String? countCompleted,
    String? countCancelled,
  }) => VendorReservationsState(
    loading: loading ?? this.loading,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    all: all ?? this.all,
    visible: visible ?? this.visible,
    countNew: countNew ?? this.countNew,
    countOngoing: countOngoing ?? this.countOngoing,
    countCompleted: countCompleted ?? this.countCompleted,
    countCancelled: countCancelled ?? this.countCancelled,
  );

  @override
  List<Object?> get props => [loading, filter, query, all, visible, countNew, countOngoing, countCompleted, countCancelled];
}
