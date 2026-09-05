// lib/logic/services/crash_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One funnel for all crash analytics (Firebase Crashlytics).
///
/// Coverage without touching every call site:
///  - Framework errors: FlutterError.onError (fatal).
///  - Anything escaping the framework: PlatformDispatcher.onError (fatal).
///  - Every bloc/cubit: [KorraBlocObserver.onError] (non-fatal).
///  - Every repository failure: KorraException records itself here as a
///    non-fatal the moment it is constructed, so even errors the UI handles
///    gracefully (snackbars, failure states) still reach the dashboard with
///    their technical details.
///
/// Crashlytics has no Flutter web support, so every entry point no-ops on web
/// (the web builds at app./business.korra.com.ng keep working unchanged).
class KorraCrash {
  KorraCrash._();

  static bool get _enabled => !kIsWeb;

  /// Call once in bootstrap, right after Firebase.initializeApp.
  static Future<void> init() async {
    if (!_enabled) return;
    final crashlytics = FirebaseCrashlytics.instance;

    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    Bloc.observer = KorraBlocObserver();

    // Crash reports carry the signed-in uid so a report can be matched to
    // the account that hit it.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      crashlytics.setUserIdentifier(user?.uid ?? '');
    });
  }

  /// Non-fatal by default; use for handled-but-noteworthy failures.
  static void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason, fatal: fatal);
  }

  /// Breadcrumb attached to the next report.
  static void log(String message) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.log(message);
  }
}

/// Reports every unhandled error thrown inside any bloc or cubit — one
/// observer instead of try/catch edits in each of them.
class KorraBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    KorraCrash.record(
      error,
      stackTrace,
      reason: 'Unhandled error in ${bloc.runtimeType}',
    );
    super.onError(bloc, error, stackTrace);
  }
}
