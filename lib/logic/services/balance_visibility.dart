import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One app-wide "hide my money" switch. The wallet card's eye toggle and the
/// Bank Details balance read the SAME state, so hiding in one place hides in
/// the other (and vice versa). Persisted across launches.
class BalanceVisibility {
  BalanceVisibility._();

  static const _prefsKey = 'korra_balance_visible';

  /// Listen with a ValueListenableBuilder; flip with [toggle].
  static final ValueNotifier<bool> visible = ValueNotifier<bool>(true);

  static bool _loaded = false;

  /// Cheap to call from every screen that shows a balance — only the first
  /// call actually touches SharedPreferences.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      visible.value = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      // keep default (visible) if prefs are unavailable
    }
  }

  static void toggle() {
    visible.value = !visible.value;
    _save();
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, visible.value);
    } catch (_) {}
  }
}
