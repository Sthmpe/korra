import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/plan.dart';
import '../../../../data/repository/home_repository.dart';
import 'plans_event.dart';
import 'plans_state.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  final HomeRepository repo;
  PlansBloc(this.repo) : super(const PlansState()) {
    on<PlansStarted>(_onStarted);
    on<PlansTabChanged>((e, emit) {
      emit(state.copyWith(tab: e.tab));
      _recompute(emit);
    });
    on<PlansSearchChanged>((e, emit) {
      emit(state.copyWith(query: e.query));
      _recompute(emit);
    });
    on<PlansApplyFilters>((e, emit) {
      emit(state.copyWith(
        sortBy: e.sortBy,
        autopayOnly: e.autopayOnly,
        overdueOnly: e.overdueOnly,
        highValueOnly: e.highValueOnly,
      ));
      _recompute(emit);
    });
    on<PlansResetFilters>((e, emit) {
      emit(state.copyWith(
        sortBy: SortBy.nextDue,
        autopayOnly: false,
        overdueOnly: false,
        highValueOnly: false,
      ));
      _recompute(emit);
    });
  }

  Future<void> _onStarted(PlansStarted e, Emitter<PlansState> emit) async {
    emit(state.copyWith(loading: true));
    final plans = await repo.fetchPlans(); // <-- YOUR DATA
    emit(state.copyWith(loading: false, all: plans));
    _recompute(emit);
  }

  // --- helpers --------------------------------------------------------------

  void _recompute(Emitter<PlansState> emit) {
    List<Plan> out = List.of(state.all);

    // status (demo): use progress to simulate completed/overdue
    bool isCompleted(Plan p) => p.progress >= 100;
    bool isOverdue(Plan p) => p.progress < 15; // demo “overdue”
    bool isActive(Plan p) => !isCompleted(p) && !isOverdue(p);

    // Tab filter
    out = out.where((p) {
      switch (state.tab) {
        case PlansTab.active:    return isActive(p);
        case PlansTab.completed: return isCompleted(p);
        case PlansTab.overdue:   return isOverdue(p);
      }
    }).toList();

    // Extra filters
    if (state.autopayOnly) {
      out = out.where((p) => _isAutopay(p)).toList();
    }
    if (state.overdueOnly) {
      out = out.where((p) => isOverdue(p)).toList();
    }
    if (state.highValueOnly) {
      out = out.where((p) => _isHighValue(p)).toList();
    }

    // Search
    final q = state.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((p) =>
        p.title.toLowerCase().contains(q) || p.vendor.toLowerCase().contains(q)
      ).toList();
    }

    // Sort
    switch (state.sortBy) {
      case SortBy.nextDue:
        out.sort((a,b) => _dueWeight(a.nextDue).compareTo(_dueWeight(b.nextDue)));
        break;
      case SortBy.amount:
        out.sort((a,b) => _amount(b).compareTo(_amount(a))); // desc
        break;
      case SortBy.progress:
        out.sort((a,b) => b.progress.compareTo(a.progress));
        break;
    }

    emit(state.copyWith(visible: out));
  }

  // --- derived props --------------------------------------------------------

  // demo autopay: deterministic
  bool _isAutopay(Plan p) => p.id.hashCode.isEven;

  bool _isHighValue(Plan p) {
    final remain = _currencyToInt(p.amountRemainText);
    final next   = _currencyToInt(p.nextAmountText);
    return remain >= 300000 || next >= 50000;
  }

  int _amount(Plan p) => _currencyToInt(p.nextAmountText) + _currencyToInt(p.amountRemainText);

  int _currencyToInt(String? s) {
    if (s == null || s.isEmpty) return 0;
    final digits = RegExp(r'[0-9]+').allMatches(s).map((m) => m.group(0)!).join();
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  // “Due Today / Due Mon / Due Fri …” → weight for sorting
  int _dueWeight(String label) {
    final map = {
      'today': 0, 'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7,
    };
    final lower = label.toLowerCase();
    for (final k in map.keys) {
      if (lower.contains(k)) return map[k]!;
    }
    return 99; // unknown goes last
  }
}
