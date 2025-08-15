import 'package:equatable/equatable.dart';

import '../../../../data/models/activity_item.dart';
import '../../../../data/models/plan.dart';
import '../../../../data/models/vendor.dart';

enum HomeStatus { idle, loading, loaded, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final String walletBalance;
  final String defaultMethodMasked;
  final List<Plan> plans;
  final List<Vendor> vendors;
  final List<ActivityItem> activity;
  final String? message;

  const HomeState({
    this.status = HomeStatus.idle,
    this.walletBalance = '—',
    this.defaultMethodMasked = '—',
    this.plans = const [],
    this.vendors = const [],
    this.activity = const [],
    this.message,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? walletBalance,
    String? defaultMethodMasked,
    List<Plan>? plans,
    List<Vendor>? vendors,
    List<ActivityItem>? activity,
    String? message,
  }) {
    return HomeState(
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      defaultMethodMasked: defaultMethodMasked ?? this.defaultMethodMasked,
      plans: plans ?? this.plans,
      vendors: vendors ?? this.vendors,
      activity: activity ?? this.activity,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, walletBalance, defaultMethodMasked, plans, vendors, activity, message];
}
