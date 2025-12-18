// lib/logic/bloc/vendor/home/vendor_home_bloc.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../data/models/vendor/transaction_model.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../core/net/net_cubit.dart';
import 'vendor_home_event.dart';
import 'vendor_home_state.dart';

class VendorHomeBloc extends Bloc<VendorHomeEvent, VendorHomeState> {
  final VendorRepository vendors;
  final String vendorUid;
  final NetCubit net;

  VendorHomeBloc({
    required this.vendors,
    required this.vendorUid,
    required this.net,
  }) : super(VendorHomeState.initial()) {
    on<VendorHomeStarted>(_onStarted);
    on<VendorHomeRefresh>(_onRefresh);
    on<ManagePayoutMethod>(_onManagePayoutMethod);
    on<ViewHoldSchedule>(_onViewHoldSchedule);
    on<VendorStatsUpdated>(_onStatsUpdated);
  }

  Future<void> _onStarted(
    VendorHomeStarted event,
    Emitter<VendorHomeState> emit,
  ) async {
    // Start listening to the Ledger Stream
    _subscribeToStats(emit);
    await _subscribeToLedger(emit);
  }

  Future<void> _onRefresh(
    VendorHomeRefresh event,
    Emitter<VendorHomeState> emit,
  ) async {
    // Re-subscribe or trigger any other refresh logic needed
    // Since it's a stream, it updates automatically, but we can force a reload of other data like KPIs
    _subscribeToStats(emit);
    await _subscribeToLedger(emit);
  }

  void _onStatsUpdated(VendorStatsUpdated event, Emitter<VendorHomeState> emit) {
    emit(state.copyWith(
      maxLimit: event.stats.maxReservationLimit,
      activePlanValue: event.stats.currentActivePlanValue,
      liabilityValue: event.stats.totalLiability,
    ));
  }

  // New Helper to listen to Limits/Liabilities
  void _subscribeToStats(Emitter<VendorHomeState> emit) {
     // Note: In a real Bloc, use `emit.forEach` or `StreamSubscription`. 
     // Since `emit.forEach` blocks, we can't easily chain two of them in one handler without RxDart.
     // THE EASY FLUTTER FIX: Just trigger a state update when stats change.
     
     vendors.streamVendorStats(vendorUid).listen((stats) {
       if (!isClosed) {
         add(VendorStatsUpdated(stats)); // Need to create this internal event
       }
     });
  }

  Future<void> _subscribeToLedger(Emitter<VendorHomeState> emit) async {
    emit(state.copyWith(status: VendorHomeStatus.loading));

    await emit.forEach<List<TransactionModel>>(
      vendors.streamLedger(vendorUid), // Ensure this exists in Repo
      onData: (transactions) {
        final now = DateTime.now();

        // --- REAL LOGIC ---
        double totalEarnings = 0;
        double lockedFunds = 0;
        Map<String, double> groupedLocks = {}; 

        for (var tx in transactions) {
          totalEarnings += tx.amount;
          if (tx.amount > 0 && 
              tx.status != 'cancelled' && 
              tx.releaseDate != null && 
              tx.releaseDate!.isAfter(now)) {
             lockedFunds += tx.amount;
             String dateKey = tx.releaseDate!.toIso8601String().split('T')[0];
             if (groupedLocks.containsKey(dateKey)) {
               groupedLocks[dateKey] = groupedLocks[dateKey]! + tx.amount;
             } else {
               groupedLocks[dateKey] = tx.amount;
             }
          }
        }
        var sortedKeys = groupedLocks.keys.toList()..sort();
        List<HoldEntry> releases = sortedKeys.map((key) {
           final dateObj = DateTime.parse(key); 
           return HoldEntry(
             dateLabel: DateFormat('MMM dd').format(dateObj),
             amountText: '₦${formatToCurrency(groupedLocks[key]!)}',
             date: dateObj, 
             released: false
           );
        }).toList();
        
        // -------------------------------------------

        // 4. Calculate Days Remaining (using the sorted list)
        int daysRemaining = 0;
        String nextReleaseStr = '--';

        if (releases.isNotEmpty) {
           // We use releases.first because we just sorted them above
           final firstDate = releases.first.date; 
           
           nextReleaseStr = DateFormat('MMM dd').format(firstDate);
           
           final diff = firstDate.difference(now);
           daysRemaining = diff.inDays;

           // Visual Polish: If it's less than 24h but in the future, show "1 day" instead of "0 days"
           if (daysRemaining == 0 && firstDate.isAfter(now)) {
             daysRemaining = 1; 
           }
        }

        // 5. Calculate Withdrawable
        double withdrawable = totalEarnings - lockedFunds;

        // 6. Update KPIs (Placeholders for now, connect to real stream later)
        // You might want to run a separate stream for these if they are complex queries
        final newCount = '0'; 
        final ongoingCount = '0';

        return state.copyWith(
          status: VendorHomeStatus.success,
          walletBalance: totalEarnings, // Total Accumulated
          withdrawable: withdrawable,   // Liquid
          onHold: lockedFunds,          // Vault
          nextReleaseDate: nextReleaseStr,
          daysRemaining: daysRemaining,
          upcomingReleases: releases,
          newCount: newCount,
          ongoingCount: ongoingCount,
        );
      },
      onError: (error, stack) {
        debugPrint("Ledger Stream Error: $error");
        return state.copyWith(status: VendorHomeStatus.failure);
      },
    );
  }

  Future<void> _onManagePayoutMethod(
    ManagePayoutMethod event,
    Emitter<VendorHomeState> emit,
  ) async {
    emit(state.copyWith(navigateToPayout: true));
  }

  void _onViewHoldSchedule(
    ViewHoldSchedule event,
    Emitter<VendorHomeState> emit,
  ) {
    // Navigate to dedicated Vault Screen
    Get.toNamed('/vendor/vault'); // Or use Get.to(() => VaultScreen());
  }
}