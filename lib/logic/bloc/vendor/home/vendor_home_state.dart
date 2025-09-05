import 'package:equatable/equatable.dart';

import '../../../../data/models/vendor/vendor_activity.dart';

enum VendorHomeStatus { initial, loading, success, failure }

enum ResvFilter { newRes, ongoing, completed, cancelled }

class VendorHomeState extends Equatable {
  final VendorHomeStatus status;

  final String withdrawable;         // formatted: ₦4,800,000
  final int withdrawableMinor;       // enable/disable payout button
  final String payoutMethodMasked;   // e.g. 'GTB ••1234' or 'Add method'
  final String onHold;               // e.g. ₦1,300,000
  final String nextReleaseDate;      // e.g. Aug 27
  final String newCount;
  final String ongoingCount;
  final String completedCount;
  final String cancelledCount;
  final List<VendorActivity> activities;

  const VendorHomeState({
    required this.status,
    required this.withdrawable,
    required this.withdrawableMinor,
    required this.payoutMethodMasked,
    required this.onHold,
    required this.nextReleaseDate,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.activities,
  });

factory VendorHomeState.initial() => const VendorHomeState(
      status: VendorHomeStatus.initial,
      // ▼ Use more descriptive placeholders
      withdrawable: '₦--',
      withdrawableMinor: 0,
      payoutMethodMasked: '...',
      onHold: '₦--',
      nextReleaseDate: '--',
      newCount: '-',
      ongoingCount: '-',
      completedCount: '-',
      cancelledCount: '-',
      activities: [],
    );

  VendorHomeState copyWith({
    VendorHomeStatus? status,
    String? withdrawable,
    int? withdrawableMinor,
    String? payoutMethodMasked,
    String? onHold,
    String? nextReleaseDate,
    String? newCount,
    String? ongoingCount,
    String? completedCount,
    String? cancelledCount,
    List<VendorActivity>? activities,
  }) {
    return VendorHomeState(
      status: status ?? this.status,
      withdrawable: withdrawable ?? this.withdrawable,
      withdrawableMinor: withdrawableMinor ?? this.withdrawableMinor,
      payoutMethodMasked: payoutMethodMasked ?? this.payoutMethodMasked,
      onHold: onHold ?? this.onHold,
      nextReleaseDate: nextReleaseDate ?? this.nextReleaseDate,
      newCount: newCount ?? this.newCount,
      ongoingCount: ongoingCount ?? this.ongoingCount,
      completedCount: completedCount ?? this.completedCount,
      cancelledCount: cancelledCount ?? this.cancelledCount,
      activities: activities ?? this.activities,
    );
  }

  @override
  List<Object?> get props => [
        status, 
        withdrawable,
        withdrawableMinor,
        payoutMethodMasked,
        onHold,
        nextReleaseDate,
        newCount,
        ongoingCount,
        completedCount,
        cancelledCount,
        activities,
      ];
}
