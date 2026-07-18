import 'package:equatable/equatable.dart';

import '../../../../data/models/customer/plans.dart';

abstract class CreatePlanEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadPlanPreview extends CreatePlanEvent {
  final double productPrice;
  final String customerUid;
  final String productId;
  final int? merchantDurationDays;
  final bool? allowExtension;
  final int? extensionDays;
  final int? noticeDays;

  /// Chosen variant for products with variants; null otherwise.
  final String? variantLabel;

  LoadPlanPreview(
    this.productPrice,
    this.customerUid,
    this.productId,
    this.merchantDurationDays,
    this.allowExtension,
    this.extensionDays,
    this.noticeDays, {
    this.variantLabel,
  });
}

class ConfirmPlanCreation extends CreatePlanEvent {
  final Plan planModel;
  final double downPayment;
  ConfirmPlanCreation(this.planModel, this.downPayment);
}