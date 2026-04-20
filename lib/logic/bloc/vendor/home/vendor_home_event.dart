import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/transaction_model.dart';
import '../../../../data/models/vendor/vendor_stat.dart';
import 'vendor_home_state.dart';

abstract class VendorHomeEvent extends Equatable {
  const VendorHomeEvent();
  @override
  List<Object?> get props => [];
}

class VendorHomeStarted extends VendorHomeEvent {
  const VendorHomeStarted();
}

class VendorStatsUpdated extends VendorHomeEvent {
  final VendorStats stats;
  const VendorStatsUpdated(this.stats);
}

class VendorLedgerUpdated extends VendorHomeEvent {
  final List<TransactionModel> transactions;
  const VendorLedgerUpdated(this.transactions);
}

class VendorHomeRefresh extends VendorHomeEvent {
  const VendorHomeRefresh();
}

class OpenReservations extends VendorHomeEvent {
  final ResvFilter filter;
  const OpenReservations({required this.filter});
  @override
  List<Object?> get props => [filter];
}

class ManagePayoutMethod extends VendorHomeEvent {
  const ManagePayoutMethod();
}

class ViewHoldSchedule extends VendorHomeEvent {
  const ViewHoldSchedule();
}

class OpenReservationDetail extends VendorHomeEvent {
  final String reservationId;
  const OpenReservationDetail(this.reservationId);
  @override
  List<Object?> get props => [reservationId];
}

class AdjustStockFor extends VendorHomeEvent {
  final String productId;
  const AdjustStockFor(this.productId);
  @override
  List<Object?> get props => [productId];
}

class OpenPlanFor extends VendorHomeEvent {
  final String refId;
  const OpenPlanFor(this.refId);
  @override
  List<Object?> get props => [refId];
}
