import '../../logic/services/crash_service.dart';

class KorraException implements Exception {
  final String message; // Friendly message for the user
  final String? technicalDetails; // Raw error for developer logs

  KorraException(this.message, {this.technicalDetails}) {
    // Every repository/service failure funnels through this exception, so
    // constructing one IS the crash-analytics hook: it lands in Crashlytics
    // as a non-fatal even when the UI handles it gracefully.
    KorraCrash.record(
      this,
      StackTrace.current,
      reason: technicalDetails ?? message,
    );
  }

  @override
  String toString() => message;
}