// lib/logic/bloc/vendor/outright_order/outright_orders_state.dart

import '../../../../data/models/vendor/outright_order.dart';

enum DeliveryStatus { initial, loading, success, failure }

class OutrightOrdersState {
  final bool loading;
  final List<OutrightOrder> visible;
  final OutrightOrderStatus filter;
  final String query;
  final String errorMessage;

  // Tab counts
  final int countPending;
  final int countReadyToDeliver;
  final int countDelivered;
  final int countCancelled;

  final DeliveryStatus deliveryStatus;

  OutrightOrdersState({
    this.loading = false,
    this.visible = const [],
    this.filter = OutrightOrderStatus.pending,
    this.query = '',
    this.errorMessage = '',
    this.countPending = 0,
    this.countReadyToDeliver = 0,
    this.countDelivered = 0,
    this.countCancelled = 0,
    this.deliveryStatus = DeliveryStatus.initial,
  });

  factory OutrightOrdersState.initial(OutrightOrderStatus initialFilter) {
    return OutrightOrdersState(filter: initialFilter);
  }

  OutrightOrdersState copyWith({
    bool? loading,
    List<OutrightOrder>? visible,
    OutrightOrderStatus? filter,
    String? query,
    String? errorMessage,
    int? countPending,
    int? countReadyToDeliver,
    int? countDelivered,
    int? countCancelled,
    DeliveryStatus? deliveryStatus,
  }) {
    return OutrightOrdersState(
      loading: loading ?? this.loading,
      visible: visible ?? this.visible,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
      countPending: countPending ?? this.countPending,
      countReadyToDeliver: countReadyToDeliver ?? this.countReadyToDeliver,
      countDelivered: countDelivered ?? this.countDelivered,
      countCancelled: countCancelled ?? this.countCancelled,
      deliveryStatus: deliveryStatus ?? DeliveryStatus.initial,
    );
  }
}
