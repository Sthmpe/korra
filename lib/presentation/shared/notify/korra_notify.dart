import 'package:flutter/material.dart';
import 'korra_notifier.dart';

enum KorraNoticeType { success, info, warning, error }

class KorraNotify {
  static void success(BuildContext context, String message, {String? actionText, VoidCallback? onAction, Duration? duration, VoidCallback? onTap}) {
    KorraNotifier.of(context).show(
      message: message,
      type: KorraNoticeType.success,
      actionText: actionText,
      onAction: onAction,
      duration: duration,
      onTap: onTap,
    );
  }

  static void info(BuildContext context, String message, {String? actionText, VoidCallback? onAction, Duration? duration, VoidCallback? onTap}) {
    KorraNotifier.of(context).show(
      message: message,
      type: KorraNoticeType.info,
      actionText: actionText,
      onAction: onAction,
      duration: duration,
      onTap: onTap,
    );
  }

  static void warning(BuildContext context, String message, {String? actionText, VoidCallback? onAction, Duration? duration, VoidCallback? onTap}) {
    KorraNotifier.of(context).show(
      message: message,
      type: KorraNoticeType.warning,
      actionText: actionText,
      onAction: onAction,
      duration: duration,
      onTap: onTap,
    );
  }

  static void error(BuildContext context, String message, {String? actionText, VoidCallback? onAction, Duration? duration, VoidCallback? onTap}) {
    KorraNotifier.of(context).show(
      message: message,
      type: KorraNoticeType.error,
      actionText: actionText,
      onAction: onAction,
      duration: duration,
      onTap: onTap,
    );
  }
}
