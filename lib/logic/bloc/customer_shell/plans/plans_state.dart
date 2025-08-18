import 'package:equatable/equatable.dart';

import '../../../../data/models/plan.dart';
import 'plans_event.dart';

class PlansState extends Equatable {
  final bool loading;
  final List<Plan> all;
  final List<Plan> visible;
  final PlansTab tab;
  final SortBy sortBy;
  final String query;
  final bool autopayOnly;
  final bool overdueOnly;
  final bool highValueOnly;

  const PlansState({
    this.loading = false,
    this.all = const [],
    this.visible = const [],
    this.tab = PlansTab.active,
    this.sortBy = SortBy.nextDue,
    this.query = '',
    this.autopayOnly = false,
    this.overdueOnly = false,
    this.highValueOnly = false,
  });

  PlansState copyWith({
    bool? loading,
    List<Plan>? all,
    List<Plan>? visible,
    PlansTab? tab,
    SortBy? sortBy,
    String? query,
    bool? autopayOnly,
    bool? overdueOnly,
    bool? highValueOnly,
  }) {
    return PlansState(
      loading: loading ?? this.loading,
      all: all ?? this.all,
      visible: visible ?? this.visible,
      tab: tab ?? this.tab,
      sortBy: sortBy ?? this.sortBy,
      query: query ?? this.query,
      autopayOnly: autopayOnly ?? this.autopayOnly,
      overdueOnly: overdueOnly ?? this.overdueOnly,
      highValueOnly: highValueOnly ?? this.highValueOnly,
    );
  }

  @override
  List<Object?> get props => [
    loading, all, visible, tab, sortBy, query, autopayOnly, overdueOnly, highValueOnly
  ];
}
