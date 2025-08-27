import 'package:equatable/equatable.dart';

import '../../../../data/models/vendor/vendor_activity.dart';

enum ResvFilter { newRes, ongoing, completed, cancelled }

class VendorHomeState extends Equatable {
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

  factory VendorHomeState.mock() => VendorHomeState(
        withdrawable: '₦4,800,000',
        withdrawableMinor: 480000000,
        payoutMethodMasked: 'GTB ••1289',
        onHold: '₦1,300,000',
        nextReleaseDate: 'Aug 27',
        newCount: '3',
        ongoingCount: '12',
        completedCount: '28',
        cancelledCount: '2',
        activities: const [
          VendorActivity(
            id: 'a1',
            refId: 'r_102',
            type: VendorActivityType.newReservation,
            title: 'New reservation • Bose 700',
            subtitle: 'Hold ends in 9 days',
          ),
          VendorActivity(
            id: 'a2',
            refId: 'r_087',
            type: VendorActivityType.paymentMissed,
            title: 'Missed payment • John D.',
            subtitle: 'Due Aug 17 — system will retry',
          ),
          VendorActivity(
            id: 'a3',
            refId: 'p_002',
            type: VendorActivityType.lowStock,
            title: 'Low stock • AirPods Pro 2',
            subtitle: 'Only 2 left — update stock',
          ),
        ],
      );

  VendorHomeState copyWith({
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
