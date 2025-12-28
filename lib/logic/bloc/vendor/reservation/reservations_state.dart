import '../../../../data/models/vendor/reservation.dart';

enum VerificationStatus { initial, loading, success, failure }

class ReservationsState {
  final bool loading;
  final List<Reservation> visible;
  final ReservationStatus filter;
  final String query;
  final String errorMessage;
  
  // Counts
  final int countNew;
  final int countOngoing;
  final int countReady; // ✅ NEW
  final int countCompleted;
  final int countCancelled;
  final VerificationStatus verificationStatus;

  ReservationsState({
    this.loading = false,
    this.visible = const [],
    this.filter = ReservationStatus.ongoing,
    this.query = '',
    this.errorMessage = '',
    this.countNew = 0,
    this.countOngoing = 0,
    this.countReady = 0, // ✅ NEW
    this.countCompleted = 0,
    this.countCancelled = 0,
    this.verificationStatus = VerificationStatus.initial,
  });

  factory ReservationsState.initial(ReservationStatus initialFilter) {
    return ReservationsState(filter: initialFilter);
  }

  ReservationsState copyWith({
    bool? loading,
    List<Reservation>? visible,
    ReservationStatus? filter,
    String? query,
    String? errorMessage,
    int? countNew,
    int? countOngoing,
    int? countReady, // ✅ NEW
    int? countCompleted,
    int? countCancelled,
    VerificationStatus? verificationStatus,
  }) {
    return ReservationsState(
      loading: loading ?? this.loading,
      visible: visible ?? this.visible,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
      countNew: countNew ?? this.countNew,
      countOngoing: countOngoing ?? this.countOngoing,
      countReady: countReady ?? this.countReady, // ✅ NEW
      countCompleted: countCompleted ?? this.countCompleted,
      countCancelled: countCancelled ?? this.countCancelled,
      verificationStatus: verificationStatus ?? VerificationStatus.initial,
    );
  }
}