import 'package:equatable/equatable.dart';

enum PlansTab { active, completed, overdue }
enum SortBy { nextDue, amount, progress }

abstract class PlansEvent extends Equatable {
  const PlansEvent();
  @override
  List<Object?> get props => [];
}

class PlansStarted extends PlansEvent {}

class PlansTabChanged extends PlansEvent {
  final PlansTab tab;
  const PlansTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

class PlansSearchChanged extends PlansEvent {
  final String query;
  const PlansSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class PlansApplyFilters extends PlansEvent {
  final SortBy sortBy;
  final bool autopayOnly;
  final bool overdueOnly;
  final bool highValueOnly;
  const PlansApplyFilters({
    required this.sortBy,
    required this.autopayOnly,
    required this.overdueOnly,
    required this.highValueOnly,
  });
  @override
  List<Object?> get props => [sortBy, autopayOnly, overdueOnly, highValueOnly];
}

class PlansResetFilters extends PlansEvent {}
