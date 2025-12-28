import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for lastDoc
import '../../../../data/models/vendor/reservation.dart';
import '../../../../data/repository/vendors/reservations_repository.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import 'reservations_event.dart';
import 'reservations_state.dart';

class ReservationsBloc extends Bloc<ReservationsEvent, ReservationsState> {
  final VendorRepository repo;
  final String vendorId;
  
  // Keep track of the last document for pagination (if you add LoadMore later)
  DocumentSnapshot? _lastDoc; 

  ReservationsBloc({required this.repo, required this.vendorId, required ReservationStatus initial})
      : super(ReservationsState.initial(initial)) {
    
    on<ResStarted>(_onStarted);
    on<ResRefresh>(_onRefresh);
    on<ResChangeFilter>(_onChangeFilter);
    on<ResSearchChanged>(_onSearchChanged);
    
    // Wire Prompt Actions
    on<ResOpen>((e, _) {});
    on<ResArrangeDelivery>((e, _) {});
    on<ResVerifyPickup>(_onVerifyPickup);
  }

  Future<void> _onStarted(ResStarted event, Emitter<ReservationsState> emit) async {
    emit(state.copyWith(loading: true, filter: event.filter));
    
    // 1. Fetch List
    // 2. Fetch Counts (Parallel)
    try {
        final results = await Future.wait([
            repo.getReservations(status: event.filter, vendorId: vendorId, limit: 20),
            repo.getCounts(vendorId), // ✅ Ensure this is called
        ]);

        final items = results[0] as List<Reservation>;
        final counts = results[1] as Map<ReservationStatus, int>;

        emit(state.copyWith(
          loading: false,
          visible: items,
          countNew: counts[ReservationStatus.newRes] ?? 0,
          countOngoing: counts[ReservationStatus.ongoing] ?? 0,
          
          // ✅ MAP READY COUNT
          countReady: counts[ReservationStatus.readyForPickup] ?? 0,
          
          countCompleted: counts[ReservationStatus.completed] ?? 0,
          countCancelled: counts[ReservationStatus.cancelled] ?? 0,
        ));
    } catch (e) {
        emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onChangeFilter(ResChangeFilter e, Emitter<ReservationsState> emit) async {
    if (e.filter == state.filter) return;
    
    // 1. Reset State for new tab
    _lastDoc = null; 
    emit(state.copyWith(
      filter: e.filter, 
      visible: [], 
      loading: true,
      query: '' // Clear search on tab change
    ));
    
    // 2. Load new data
    await _loadData(emit);
  }

  Future<void> _onRefresh(ResRefresh e, Emitter<ReservationsState> emit) async {
    _lastDoc = null;
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<ReservationsState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      // 1. Fetch Lists based on CURRENT filter
      final items = await repo.getReservations(
        status: state.filter,
        vendorId: vendorId,
        limit: 20, 
        // lastDoc: _lastDoc // Pass this if implementing pagination
      );

      // 2. Fetch Counts (Optional: Update badges)
      // Since we aren't loading ALL items anymore, we need the repo to tell us the counts
      final counts = await repo.getCounts(vendorId);

      emit(state.copyWith(
        loading: false,
        visible: items,
        // Update counts from server/repo logic
        countNew: counts[ReservationStatus.newRes] ?? 0,
        countOngoing: counts[ReservationStatus.ongoing] ?? 0,
        countCompleted: counts[ReservationStatus.completed] ?? 0,
        countCancelled: counts[ReservationStatus.cancelled] ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false));
      // Handle error state if needed
    }
  }

  void _onSearchChanged(ResSearchChanged e, Emitter<ReservationsState> emit) {
    // Note: This searches ONLY the visible items fetched so far.
    // For global search, you would need a repo.search() method.
    emit(state.copyWith(query: e.query));
  }

  Future<void> _onVerifyPickup(ResVerifyPickup event, Emitter<ReservationsState> emit) async {
    emit(state.copyWith(verificationStatus: VerificationStatus.loading));
    
    try {
      await repo.verifyPickup(
        planId: event.planId, 
        pin: event.pin, 
        customerUid: event.customerId,
        vendorUid: vendorId // BLoC knows the vendorId
      );
      
      // Success!
      // Optionally refresh the list to move item from 'Ready' to 'History' tab logic if needed
      // But for now, just signal success to UI.
      emit(state.copyWith(verificationStatus: VerificationStatus.success));
      
      // Reset status after a moment so user can verify another if needed without reload
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(verificationStatus: VerificationStatus.initial));
      
      // Trigger a data refresh to update the list in background
      add(const ResRefresh()); 

    } catch (e) {
      emit(state.copyWith(
        verificationStatus: VerificationStatus.failure,
        errorMessage: e.toString() // Or clean error message
      ));
      
      // Reset after error too
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(verificationStatus: VerificationStatus.initial));
    }
  }
}