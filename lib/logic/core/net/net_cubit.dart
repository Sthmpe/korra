import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Traffic light for the app:
/// - checking: only used at startup (and briefly on OS events), non-blocking in UI
/// - online: end-to-end reachability confirmed
/// - offline: confirmed offline; UI shows blocking sheet
enum NetState { checking, online, offline }

class NetCubit extends Cubit<NetState> {
  NetCubit({
    this.probeTimeout = const Duration(seconds: 3),
    this.postOnlineGrace = const Duration(minutes: 2),
  }) : super(NetState.checking);

  final Duration probeTimeout;
  final Duration postOnlineGrace;

  // Backoff schedule used ONLY while offline
  static const List<Duration> _offlineBackoff = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 40),
    Duration(minutes: 1),
    Duration(minutes: 2),
  ];

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _offlineTimer;
  int _backoffIndex = 0;
  int _failStreak = 0;
  DateTime? _lastOnlineAt;
  bool _probing = false;

  /// Start listening to OS connectivity and run an initial probe.
  void start() {
    // Initial: block only until first probe resolves.
    emit(NetState.checking);
    _probeAndMaybeTransition(initial: true);

    _connSub = Connectivity()
        .onConnectivityChanged
        .listen((_) {
          // OS says something changed. Run a quick probe, but don't spam.
          // This brief “checking” lets UI show a tiny banner (non-blocking).
          emit(NetState.checking);
          _probeAndMaybeTransition();
        });
  }

  /// Manual user-triggered recheck (e.g., "Retry now" button).
  void retryNow() => _probeAndMaybeTransition(force: true);

  /// Preflight to call right before risky actions (login/pay/submit).
  /// Returns true if *now* online; false if offline (and will transition to offline state).
  Future<bool> preflight() async {
    final ok = await _probeInternet();
    if (ok) {
      _markOnline();
      return true;
    } else {
      _markOffline();
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _connSub?.cancel();
    _offlineTimer?.cancel();
    return super.close();
  }

  // ---------------- Internal logic ----------------

  Future<void> _probeAndMaybeTransition({bool initial = false, bool force = false}) async {
    if (_probing) return;
    _probing = true;
    try {
      final ok = await _probeInternet();

      if (ok) {
        _markOnline();
      } else {
        // Hysteresis: require 2 consecutive fails to declare offline from online.
        if (state == NetState.online && !initial) {
          _failStreak++;
          if (_failStreak >= 2) {
            _markOffline();
          } else {
            // stay in online temporarily; no UI flicker
            _scheduleOfflineBackoff();
          }
        } else {
          _markOffline();
        }
      }
    } finally {
      _probing = false;
    }
  }

  void _markOnline() {
    _failStreak = 0;
    _offlineTimer?.cancel();
    _backoffIndex = 0;

    if (state != NetState.online) {
      emit(NetState.online);
    }
    _lastOnlineAt = DateTime.now();
  }

  void _markOffline() {
    if (state != NetState.offline) {
      emit(NetState.offline);
    }
    _scheduleOfflineBackoff();
  }

  void _scheduleOfflineBackoff() {
    _offlineTimer?.cancel();
    final delay = _offlineBackoff[_backoffIndex.clamp(0, _offlineBackoff.length - 1)];
    _backoffIndex = (_backoffIndex + 1).clamp(0, _offlineBackoff.length - 1);
    _offlineTimer = Timer(delay, () {
      // If we recently came online, skip auto-recheck for grace period
      final lastOk = _lastOnlineAt;
      if (lastOk != null && DateTime.now().difference(lastOk) < postOnlineGrace) {
        return; // grace: do nothing; we'll get OS events or user retry
      }
      _probeAndMaybeTransition();
    });
  }

  /// Very small, reliable 204 probes (no hosting needed).
  Future<bool> _probeInternet() async {
    const urls = <String>[
      'https://www.google.com/generate_204',
      'https://clients3.google.com/generate_204',
      'https://www.gstatic.com/generate_204',
    ];
    for (final u in urls) {
      if (await _probe204(u)) return true;
    }
    return false;
  }

  Future<bool> _probe204(String url) async {
    final c = HttpClient()..connectionTimeout = probeTimeout;
    try {
      final req = await c.headUrl(Uri.parse(url)).timeout(probeTimeout);
      req.headers.set(HttpHeaders.userAgentHeader, 'korra-net-probe');
      final resp = await req.close().timeout(probeTimeout);
      return resp.statusCode == 204 || (resp.statusCode >= 200 && resp.statusCode < 300);
    } catch (_) {
      return false;
    } finally {
      c.close(force: true);
    }
  }
}
