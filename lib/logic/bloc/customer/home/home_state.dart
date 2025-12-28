import 'package:equatable/equatable.dart';

import '../../../../data/models/customer/activity_item.dart';

enum HomeStatus { idle, initial, loading, loaded, failure, success }

class HomeState extends Equatable {
  final HomeStatus status;
  final String walletBalance;
  final String defaultMethodMasked;
  final List<ActivityItem> activity;
  final String? message;

  const HomeState({
    this.status = HomeStatus.initial,
    this.walletBalance = '—',
    this.defaultMethodMasked = '—',
    this.activity = const [],
    this.message,
  });

  factory HomeState.initial() => const HomeState(
    status: HomeStatus.initial,
    walletBalance: '—',
    defaultMethodMasked: '—',
    activity: [],
  );

  HomeState copyWith({
    HomeStatus? status,
    String? walletBalance,
    String? defaultMethodMasked,
    List<ActivityItem>? activity,
    String? message,
  }) {
    return HomeState(
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      defaultMethodMasked: defaultMethodMasked ?? this.defaultMethodMasked,
      activity: activity ?? this.activity,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, walletBalance, defaultMethodMasked, activity, message];
}
