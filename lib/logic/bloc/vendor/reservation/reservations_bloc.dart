import 'package:flutter/foundation.dart';
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
  
  // 🚀 Pagination Memory
  DocumentSnapshot? _lastDoc; 
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  ReservationsBloc({required this.repo, required this.vendorId, required ReservationStatus initial})
      : super(ReservationsState.initial(initial)) {
    
    on<ResStarted>(_onStarted);
    on<ResRefresh>(_onRefresh);
    on<ResChangeFilter>(_onChangeFilter);
    on<ResSearchChanged>(_onSearchChanged);
    on<ResLoadMore>(_onLoadMore); // 🚀 Wire up Load More
    
    // Wire Prompt Actions
    on<ResOpen>((e, _) {});
    on<ResArrangeDelivery>((e, _) {});
    on<ResVerifyPickup>(_onVerifyPickup);
  }

  Future<void> _onStarted(ResStarted event, Emitter<ReservationsState> emit) async {
    emit(state.copyWith(loading: true, filter: event.filter));
    
    _lastDoc = null;
    _hasReachedMax = false;

    try {
        final results = await Future.wait([
            // 🚀 Call the new Paginated Method
            repo.getReservations(status: event.filter, vendorId: vendorId, limit: 15),
            repo.getCounts(vendorId), 
        ]);

        // 🚀 Unpack the Map
        final mapResult = results[0] as Map<String, dynamic>;
        final counts = results[1] as Map<ReservationStatus, int>;

        final items = mapResult['items'] as List<Reservation>;
        _lastDoc = mapResult['lastDoc'] as DocumentSnapshot?;
        _hasReachedMax = mapResult['hasReachedMax'] as bool;

        emit(state.copyWith(
          loading: false,
          visible: items,
          countNew: counts[ReservationStatus.newRes] ?? 0,
          countOngoing: counts[ReservationStatus.ongoing] ?? 0,
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
    
    // 1. Reset State & Pagination for new tab
    _lastDoc = null; 
    _hasReachedMax = false;

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
    _hasReachedMax = false;
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<ReservationsState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      // 🚀 Use the new paginated method
      final mapResult = await repo.getReservations(
        status: state.filter,
        vendorId: vendorId,
        limit: 15, 
      );

      _lastDoc = mapResult['lastDoc'] as DocumentSnapshot?;
      _hasReachedMax = mapResult['hasReachedMax'] as bool;

      final items = mapResult['items'] as List<Reservation>;
      final counts = await repo.getCounts(vendorId);

      emit(state.copyWith(
        loading: false,
        visible: items,
        countNew: counts[ReservationStatus.newRes] ?? 0,
        countOngoing: counts[ReservationStatus.ongoing] ?? 0,
        countReady: counts[ReservationStatus.readyForPickup] ?? 0,
        countCompleted: counts[ReservationStatus.completed] ?? 0,
        countCancelled: counts[ReservationStatus.cancelled] ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  // =========================================================
  // 🚀 PAGINATION: LOAD MORE
  // =========================================================
  Future<void> _onLoadMore(ResLoadMore event, Emitter<ReservationsState> emit) async {
    // Prevent spam fetching if already loading or if there is no more data
    if (_hasReachedMax || _isLoadingMore) return;
    
    _isLoadingMore = true;

    try {
      final mapResult = await repo.getReservations(
        status: state.filter, 
        vendorId: vendorId, 
        lastDoc: _lastDoc,
        limit: 15,
      );

      _lastDoc = mapResult['lastDoc'] as DocumentSnapshot?;
      _hasReachedMax = mapResult['hasReachedMax'] as bool;

      // Combine old items with the newly fetched items
      final newItems = mapResult['items'] as List<Reservation>;
      final updatedList = List<Reservation>.from(state.visible)..addAll(newItems);

      emit(state.copyWith(visible: updatedList));
    } catch (e) {
      debugPrint("Pagination Error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onSearchChanged(ResSearchChanged e, Emitter<ReservationsState> emit) {
    emit(state.copyWith(query: e.query));
  }

  Future<void> _onVerifyPickup(ResVerifyPickup event, Emitter<ReservationsState> emit) async {
    emit(state.copyWith(verificationStatus: VerificationStatus.loading));
    
    try {
      await repo.verifyPickup(
        planId: event.planId, 
        pin: event.pin, 
        customerUid: event.customerId,
        vendorUid: vendorId 
      );
      
      emit(state.copyWith(verificationStatus: VerificationStatus.success));
      
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(verificationStatus: VerificationStatus.initial));
      
      add(const ResRefresh()); 

    } catch (e) {
      emit(state.copyWith(
        verificationStatus: VerificationStatus.failure,
        errorMessage: e.toString() 
      ));
      
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(verificationStatus: VerificationStatus.initial));
    }
  }
}