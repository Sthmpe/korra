import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/vendor/vendor_reservation.dart';
import '../../../../data/repository/vendors/vendor_reservations_repository.dart';
import 'vendor_reservations_event.dart';
import 'vendor_reservations_state.dart';

class VendorReservationsBloc extends Bloc<VendorReservationsEvent, VendorReservationsState> {
  final VendorReservationsRepository repo;

  VendorReservationsBloc({required this.repo, required ReservationStatus initial})
      : super(VendorReservationsState.initial(initial)) {
    on<VResStarted>(_start);
    on<VResRefresh>(_loadAll);
    on<VResChangeFilter>((e, emit) => _apply(emit, filter: e.filter));
    on<VResSearchChanged>((e, emit) => _apply(emit, query: e.query));
    
    // Wire Prompt Actions
    on<VResOpen>((e, _) { /* Navigation handled in UI via Listener */ });
    on<VResArrangeDelivery>((e, _) { /* Logic handled in UI via Listener */ });
  }

  Future<void> _start(VResStarted e, Emitter<VendorReservationsState> emit) async {
    // ✅ Fix: Now 'e.filter' is defined in the event
    emit(state.copyWith(filter: e.filter)); 
    await _loadAll(null, emit);
  }

  Future<void> _loadAll(VResRefresh? _, Emitter<VendorReservationsState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final all = await repo.fetchAll();
      emit(_derive(state.copyWith(all: all, loading: false)));
    } catch (e) {
      emit(state.copyWith(loading: false));
    }
  }

  void _apply(Emitter<VendorReservationsState> emit, {ReservationStatus? filter, String? query}) {
    final next = state.copyWith(
      filter: filter ?? state.filter,
      query: query ?? state.query,
    );
    emit(_derive(next));
  }

  VendorReservationsState _derive(VendorReservationsState s) {
    // Bucket lists
    final newL = s.all.where((r) => r.status == ReservationStatus.newRes).toList();
    final onL  = s.all.where((r) => r.status == ReservationStatus.ongoing).toList();
    final done = s.all.where((r) => r.status == ReservationStatus.completed).toList();
    final canc = s.all.where((r) => r.status == ReservationStatus.cancelled).toList();

    // Select visible
    List<VendorReservation> vis = switch (s.filter) {
      ReservationStatus.newRes => newL,
      ReservationStatus.ongoing => onL,
      ReservationStatus.completed => done,
      ReservationStatus.cancelled => canc,
    };

    // Filter by query
    if (s.query.trim().isNotEmpty) {
      final q = s.query.toLowerCase();
      vis = vis.where((r) =>
        r.productTitle.toLowerCase().contains(q) ||
        r.customerName.toLowerCase().contains(q) ||
        r.productCode.toLowerCase().contains(q)
      ).toList();
    }

    // ✅ Return INT counts
    return s.copyWith(
      visible: vis,
      countNew: newL.length,
      countOngoing: onL.length,
      countCompleted: done.length,
      countCancelled: canc.length,
    );
  }
}