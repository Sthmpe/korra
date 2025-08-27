import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/vendor/vendor_reservation.dart';
import '../../../../data/repository/vendors/vendor_reservations_repository.dart';
import 'vendor_reservations_event.dart';
import 'vendor_reservations_state.dart';

class VendorReservationsBloc extends Bloc<VendorReservationsEvent, VendorReservationsState> {
  final VendorReservationsRepository repo;
  VendorReservationsBloc(DemoVendorReservationsRepository demoVendorReservationsRepository, {required this.repo, required ReservationStatus initial})
      : super(VendorReservationsState.initial(initial)) {
    on<VResStarted>(_start);
    on<VResRefresh>(_loadAll);
    on<VResChangeFilter>((e, emit) => _apply(emit, filter: e.filter));
    on<VResSearchChanged>((e, emit) => _apply(emit, query: e.query));
    on<VResOpen>((_, __) {}); // wire navigation where you dispatch
    on<VResArrangeDelivery>((_, __) {}); // wire prompt where you dispatch
  }

  Future<void> _start(VResStarted e, Emitter<VendorReservationsState> emit) async => _loadAll(null, emit);

  Future<void> _loadAll(VResRefresh? _, Emitter<VendorReservationsState> emit) async {
    emit(state.copyWith(loading: true));
    final all = await repo.fetchAll();
    emit(_derive(state.copyWith(all: all, loading: false)));
  }

  void _apply(Emitter<VendorReservationsState> emit, {ReservationStatus? filter, String? query}) {
    final next = state.copyWith(
      filter: filter ?? state.filter,
      query: query ?? state.query,
    );
    emit(_derive(next));
  }

  VendorReservationsState _derive(VendorReservationsState s) {
    List<VendorReservation> by(ReservationStatus st) =>
        s.all.where((r) => r.status == st).toList();

    final newL = by(ReservationStatus.newRes);
    final onL  = by(ReservationStatus.ongoing);
    final done = by(ReservationStatus.completed);
    final canc = by(ReservationStatus.cancelled);

    List<VendorReservation> vis = switch (s.filter) {
      ReservationStatus.newRes => newL,
      ReservationStatus.ongoing => onL,
      ReservationStatus.completed => done,
      ReservationStatus.cancelled => canc,
    };

    if (s.query.trim().isNotEmpty) {
      final q = s.query.toLowerCase();
      vis = vis.where((r) =>
        r.productTitle.toLowerCase().contains(q) ||
        r.customerName.toLowerCase().contains(q) ||
        r.sku.toLowerCase().contains(q)
      ).toList();
    }

    return s.copyWith(
      visible: vis,
      countNew: newL.length.toString(),
      countOngoing: onL.length.toString(),
      countCompleted: done.length.toString(),
      countCancelled: canc.length.toString(),
    );
  }
}
