// lib/logic/bloc/vendor/outright_order/outright_orders_event.dart

import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/outright_order.dart';

abstract class OutrightOrdersEvent extends Equatable {
  const OutrightOrdersEvent();

  @override
  List<Object?> get props => [];
}

class OutrightOrdersStarted extends OutrightOrdersEvent {
  final OutrightOrderStatus filter;
  const OutrightOrdersStarted(this.filter);

  @override
  List<Object?> get props => [filter];
}

class OutrightOrdersRefresh extends OutrightOrdersEvent {
  const OutrightOrdersRefresh();
}

class OutrightOrdersChangeFilter extends OutrightOrdersEvent {
  final OutrightOrderStatus filter;
  const OutrightOrdersChangeFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class OutrightOrdersLoadMore extends OutrightOrdersEvent {
  const OutrightOrdersLoadMore();
}

class OutrightOrdersSearchChanged extends OutrightOrdersEvent {
  final String query;
  const OutrightOrdersSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

// --- Multi-select (bulk mark-as-delivered; backend write not connected yet) ---

class OutrightToggleSelection extends OutrightOrdersEvent {
  final String orderId;
  const OutrightToggleSelection(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OutrightSelectAll extends OutrightOrdersEvent {
  final List<String> orderIds;
  const OutrightSelectAll(this.orderIds);

  @override
  List<Object?> get props => [orderIds];
}

class OutrightClearSelection extends OutrightOrdersEvent {
  const OutrightClearSelection();
}

class OutrightOrderMarkDelivered extends OutrightOrdersEvent {
  final String orderId;
  const OutrightOrderMarkDelivered(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Bulk mark-as-delivered for the selected outright orders.
class OutrightBulkMarkDelivered extends OutrightOrdersEvent {
  final List<String> orderIds;
  const OutrightBulkMarkDelivered(this.orderIds);

  @override
  List<Object?> get props => [orderIds];
}
