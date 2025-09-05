import 'package:korra/data/models/vendor/vendor_activity.dart';

enum PayoutChannel { bankTransfer }

class PayoutMethod {
  final PayoutChannel channel;
  final num withdrawable;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;
  const PayoutMethod({
    required this.channel,
    required this.withdrawable,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  String get masked => '${bankName.toUpperCase()} •• ${accountNumber.substring(accountNumber.length - 4)}';
}


class VendorDashboardData {
  final double withdrawable;
  final double onHold;
  final String nextReleaseDate;
  final String newCount;
  final String ongoingCount;
  final String completedCount;
  final String cancelledCount;
  final List<VendorActivity> activities;
  final PayoutMethod? payoutMethod;

  const VendorDashboardData({
    required this.withdrawable,
    required this.onHold,
    required this.nextReleaseDate,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.activities,
    this.payoutMethod,
  });

  @override
  List<Object?> get props => [
    withdrawable,
    onHold,
    nextReleaseDate,
    newCount,
    ongoingCount,
    completedCount,
    cancelledCount,
    activities,
    payoutMethod,
  ];

  VendorDashboardData copyWith({
    double? withdrawable,
    double? onHold,
    String? nextReleaseDate,
    String? newCount,
    String? ongoingCount,
    String? completedCount,
    String? cancelledCount,
    List<VendorActivity>? activities,
    PayoutMethod? payoutMethod,
  }) {
    return VendorDashboardData(
      withdrawable: withdrawable ?? this.withdrawable,
      onHold: onHold ?? this.onHold,
      nextReleaseDate: nextReleaseDate ?? this.nextReleaseDate,
      newCount: newCount ?? this.newCount,
      ongoingCount: ongoingCount ?? this.ongoingCount,
      completedCount: completedCount ?? this.completedCount,
      cancelledCount: cancelledCount ?? this.cancelledCount,
      activities: activities ?? this.activities,
      payoutMethod: payoutMethod ?? this.payoutMethod,
    );
  }
}
