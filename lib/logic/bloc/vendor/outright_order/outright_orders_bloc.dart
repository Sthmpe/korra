// lib/logic/bloc/vendor/outright_order/outright_orders_bloc.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/vendor/outright_order.dart';
import '../../../../data/repository/vendors/outright_orders_repository.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import 'outright_orders_event.dart';
import 'outright_orders_state.dart';

class OutrightOrdersBloc extends Bloc<OutrightOrdersEvent, OutrightOrdersState> {
  final VendorRepository repo;
  final String vendorId;

  DocumentSnapshot? _lastDoc;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  OutrightOrdersBloc({
    required this.repo,
    required this.vendorId,
    required OutrightOrderStatus initial,
  }) : super(OutrightOrdersState.initial(initial)) {
    on<OutrightOrdersStarted>(_onStarted);
    on<OutrightOrdersRefresh>(_onRefresh);
    on<OutrightOrdersChangeFilter>(_onChangeFilter);
    on<OutrightOrdersSearchChanged>(_onSearchChanged);
    on<OutrightOrdersLoadMore>(_onLoadMore);
    on<OutrightOrderMarkDelivered>(_onMarkDelivered);
  }

  Future<void> _onStarted(
    OutrightOrdersStarted event,
    Emitter<OutrightOrdersState> emit,
  ) async {
    emit(state.copyWith(loading: true, filter: event.filter));
    _lastDoc = null;
    _hasReachedMax = false;

    try {
      final results = await Future.wait([
        repo.getOutrightOrders(
          status: event.filter,
          vendorId: vendorId,
          limit: 15,
        ),
        repo.getOutrightCounts(vendorId),
      ]);

      final mapResult = results[0] as Map<String, dynamic>;
      final counts = results[1] as Map<OutrightOrderStatus, int>;

      final items = mapResult['items'] as List<OutrightOrder>;
      _lastDoc = mapResult['lastDoc'] as DocumentSnapshot?;
      _hasReachedMax = mapResult['hasReachedMax'] as bool;

      emit(state.copyWith(
        loading: false,
        visible: items,
        countPending: counts[OutrightOrderStatus.pending] ?? 0,
        countReadyToDeliver: counts[OutrightOrderStatus.readyToDeliver] ?? 0,
        countDelivered: counts[OutrightOrderStatus.delivered] ?? 0,
        countCancelled: counts[OutrightOrderStatus.cancelled] ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onChangeFilter(
    OutrightOrdersChangeFilter event,
    Emitter<OutrightOrdersState> emit,
  ) async {
    if (event.filter == state.filter) return;

    _lastDoc = null;
    _hasReachedMax = false;

    emit(state.copyWith(
      filter: event.filter,
      visible: [],
      loading: true,
      query: '',
    ));

    await _loadData(emit);
  }

  Future<void> _onRefresh(
    OutrightOrdersRefresh event,
    Emitter<OutrightOrdersState> emit,
  ) async {
    _lastDoc = null;
    _hasReachedMax = false;
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<OutrightOrdersState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final mapResult = await repo.getOutrightOrders(
        status: state.filter,
        vendorId: vendorId,
        limit: 15,
      );

      _lastDoc = mapResult['lastDoc'] as DocumentSnapshot?;
      _hasReachedMax = mapResult['hasReachedMax'] as bool;

      final items = mapResult['items'] as List<OutrightOrder>;
      final counts = await repo.getOutrightCounts(vendorId);

      emit(state.copyWith(
        loading: false,
        visible: items,
        countPending: counts[OutrightOrderStatus.pending] ?? 0,
        countReadyToDeliver: counts[OutrightOrderStatus.readyToDeliver] ?? 0,
        countDelivered: counts[OutrightOrderStatus.delivered] ?? 0,
        countCancelled: counts[OutrightOrderStatus.cancelled] ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    OutrightOrdersLoadMore event,
    Emitter<OutrightOrdersState> emit,
  ) async {
    if (_hasReachedMax || _isLoadingMore) return;

    _isLoadingMore = true;

    try {
      final mapResult = await repo.getOutrightOrders(
        status: state.filter,
        vendorId: vendorId,
        lastDoc: _lastDoc,
        limit: 15,
      );

      _lastDoc = mapResult['lastDoc'] as DocumentSnapshot?;
      _hasReachedMax = mapResult['hasReachedMax'] as bool;

      final newItems = mapResult['items'] as List<OutrightOrder>;
      final updatedList = List<OutrightOrder>.from(state.visible)..addAll(newItems);

      emit(state.copyWith(visible: updatedList));
    } catch (e) {
      debugPrint("OutrightOrders Pagination Error: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onSearchChanged(
    OutrightOrdersSearchChanged event,
    Emitter<OutrightOrdersState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onMarkDelivered(
    OutrightOrderMarkDelivered event,
    Emitter<OutrightOrdersState> emit,
  ) async {
    emit(state.copyWith(deliveryStatus: DeliveryStatus.loading));

    try {
      await repo.markOutrightOrderDelivered(event.orderId);

      emit(state.copyWith(deliveryStatus: DeliveryStatus.success));

      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(deliveryStatus: DeliveryStatus.initial));

      add(const OutrightOrdersRefresh());
    } catch (e) {
      emit(state.copyWith(
        deliveryStatus: DeliveryStatus.failure,
        errorMessage: e.toString(),
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(deliveryStatus: DeliveryStatus.initial));
    }
  }
}
