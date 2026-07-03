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

class OutrightOrderMarkDelivered extends OutrightOrdersEvent {
  final String orderId;
  const OutrightOrderMarkDelivered(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
