import 'package:equatable/equatable.dart';
import '../../../../data/models/vendor/vendor_activity.dart';

enum VendorHomeStatus { initial, loading, success, failure }
enum ResvFilter { newRes, ongoing, completed, cancelled }

class HoldEntry {
  final String dateLabel;   
  final String amountText;  
  final DateTime date;      
  final bool released;
  
  const HoldEntry({
    required this.dateLabel, 
    required this.amountText, 
    required this.date,
    this.released = false
  });
}

class VendorHomeState extends Equatable {
  final VendorHomeStatus status;

  // Ledger Balances
  final double walletBalance; // Total Net Worth
  final double withdrawable;  // Liquid Cash
  final double onHold;        // Vault
  
  // Limits & Capacity (Fixed: Non-nullable doubles)
  final double maxLimit;        
  final double activePlanValue; 
  final double liabilityValue;  

  // Vault Data
  final String nextReleaseDate; 
  final int daysRemaining;
  final List<HoldEntry> upcomingReleases; 

  // KPIs
  final String newCount;
  final String ongoingCount;
  final String completedCount;
  final String cancelledCount;
  
  final bool navigateToPayout;
  final List<VendorActivity> activities;

  const VendorHomeState({
    required this.status,
    required this.walletBalance,
    required this.withdrawable,
    required this.onHold,
    required this.maxLimit,       // <--- REQUIRED
    required this.activePlanValue,// <--- REQUIRED
    required this.liabilityValue, // <--- REQUIRED
    required this.nextReleaseDate,
    required this.daysRemaining,
    required this.upcomingReleases,
    required this.newCount,
    required this.ongoingCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.activities,
    this.navigateToPayout = false,
  });

  // 👇 THIS WAS LIKELY THE PROBLEM. WE MUST INIT VALUES HERE.
  factory VendorHomeState.initial() => const VendorHomeState(
    status: VendorHomeStatus.initial,
    walletBalance: 0.00,
    withdrawable: 0.00,
    onHold: 0.00,
    maxLimit: 250000.00,      // Default Tier 1 Limit
    activePlanValue: 0.00,
    liabilityValue: 0.00,
    nextReleaseDate: '--',
    daysRemaining: 0,
    upcomingReleases: [],
    newCount: '-',
    ongoingCount: '-',
    completedCount: '-',
    cancelledCount: '-',
    activities: [],
  );

  VendorHomeState copyWith({
    VendorHomeStatus? status,
    double? walletBalance,
    double? withdrawable,
    double? onHold,
    double? maxLimit,
    double? activePlanValue,
    double? liabilityValue,
    String? nextReleaseDate,
    int? daysRemaining,
    List<HoldEntry>? upcomingReleases,
    String? newCount,
    String? ongoingCount,
    String? completedCount,
    String? cancelledCount,
    List<VendorActivity>? activities,
    bool? navigateToPayout,
  }) {
    return VendorHomeState(
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      withdrawable: withdrawable ?? this.withdrawable,
      onHold: onHold ?? this.onHold,
      maxLimit: maxLimit ?? this.maxLimit,
      activePlanValue: activePlanValue ?? this.activePlanValue,
      liabilityValue: liabilityValue ?? this.liabilityValue,
      nextReleaseDate: nextReleaseDate ?? this.nextReleaseDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      upcomingReleases: upcomingReleases ?? this.upcomingReleases,
      newCount: newCount ?? this.newCount,
      ongoingCount: ongoingCount ?? this.ongoingCount,
      completedCount: completedCount ?? this.completedCount,
      cancelledCount: cancelledCount ?? this.cancelledCount,
      activities: activities ?? this.activities,
      navigateToPayout: navigateToPayout ?? this.navigateToPayout,
    );
  }

  @override
  List<Object?> get props => [
    status,
    walletBalance,
    withdrawable,
    onHold,
    maxLimit,
    activePlanValue,
    liabilityValue,
    nextReleaseDate,
    daysRemaining,
    upcomingReleases,
    newCount,
    ongoingCount,
    completedCount,
    cancelledCount,
    activities,
    navigateToPayout,
  ];
}