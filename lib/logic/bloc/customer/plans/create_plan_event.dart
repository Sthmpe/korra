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

  LoadPlanPreview(
    this.productPrice, 
    this.customerUid, 
    this.productId,
    this.merchantDurationDays,
    this.allowExtension,
    this.extensionDays,
    this.noticeDays,
  );
}

class ConfirmPlanCreation extends CreatePlanEvent {
  final Plan planModel;
  final double downPayment;
  ConfirmPlanCreation(this.planModel, this.downPayment);
}