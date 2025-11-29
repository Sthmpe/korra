import 'package:equatable/equatable.dart';

import '../../../../data/models/customer/plans.dart';


enum LinkStatus { idle, loadingProduct, loaded, validating, valid, needTopup, invalid, empty, failed, creating, success, failure }

class LinkState extends Equatable {
  final LinkStatus status;
  final String? message;
  final Plan? plan; // optional, after creation
  final ProductFetchResult? productFetch; // optional, after validation

  const LinkState({this.status = LinkStatus.idle, this.message, this.plan, this.productFetch});

  LinkState copyWith({LinkStatus? status, String? message, Plan? plan, ProductFetchResult? productFetch}) {
    return LinkState(
      status: status ?? this.status,
      message: message ?? this.message,
      plan: plan ?? this.plan,
      productFetch: productFetch ?? this.productFetch,
    );
  }

  @override
  List<Object?> get props => [status, message, plan, productFetch];
}