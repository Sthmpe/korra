import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'korra_notice.dart';
import 'korra_notify.dart';

class _NoticeJob {
  final String message;
  final KorraNoticeType type;
  final String? actionText;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback? onTap;
  _NoticeJob({
    required this.message,
    required this.type,
    this.actionText,
    this.onAction,
    required this.duration,
    this.onTap,
  });
}

/// Queue + overlay manager. Use KorraNotifier.of(context).show(...)
class KorraNotifier {
  final BuildContext context;
  OverlayEntry? _entry;
  bool _showing = false;
  final Queue<_NoticeJob> _queue = Queue();

  KorraNotifier._(this.context);

  static KorraNotifier of(BuildContext context) {
    return KorraNotifier._(context);
  }

  void show({
    required String message,
    required KorraNoticeType type,
    String? actionText,
    VoidCallback? onAction,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _queue.add(_NoticeJob(
      message: message,
      type: type,
      actionText: actionText,
      onAction: onAction,
      duration: duration ?? const Duration(milliseconds: 2800),
      onTap: onTap,
    ));
    _pump();
  }

  void _pump() {
    if (_showing || _queue.isEmpty) return;
    _showing = true;

    final job = _queue.removeFirst();
    HapticFeedback.lightImpact();

    final overlay = Overlay.of(context);
    if (overlay == null) {
      _showing = false;
      return;
    }

    _entry = OverlayEntry(
      builder: (ctx) => KorraNoticeOverlay(
        message: job.message,
        type: job.type,
        actionText: job.actionText,
        onAction: job.onAction,
        duration: job.duration,
        onTap: job.onTap,
        onDismissed: _onDismissed,
      ),
    );

    overlay.insert(_entry!);
  }

  void _onDismissed() {
    _entry?.remove();
    _entry = null;
    _showing = false;
    if (_queue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 120), _pump);
    }
  }
}
