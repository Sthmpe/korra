import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/colors.dart';
import 'korra_notify.dart';

/// Premium floating banner that slides from top, with swipe-to-dismiss and action.
class KorraNoticeOverlay extends StatefulWidget {
  final String message;
  final KorraNoticeType type;
  final String? actionText;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismissed;

  const KorraNoticeOverlay({
    super.key,
    required this.message,
    required this.type,
    this.actionText,
    this.onAction,
    required this.duration,
    this.onTap,
    required this.onDismissed,
  });

  @override
  State<KorraNoticeOverlay> createState() => _KorraNoticeOverlayState();
}

class _KorraNoticeOverlayState extends State<KorraNoticeOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _slide = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
    _c.forward();

    Future.delayed(widget.duration, _autoDismiss);
  }

  void _autoDismiss() {
    if (!mounted || _dismissed) return;
    _dismiss();
  }

  void _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    await _c.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(widget.type);

    // position just under status bar
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false, // allow taps on banner
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, (topInset > 0 ? 4.h : 10.h), 12.w, 0),
                child: Dismissible(
                  key: const ValueKey('korra_notice'),
                  direction: DismissDirection.up,
                  onDismissed: (_) => _dismiss(),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: widget.onTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: const Color(0xFFEAE6E2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                // accent stripe
                                Positioned.fill(
                                  left: 0,
                                  child: Container(
                                    width: 6.w,
                                    decoration: BoxDecoration(
                                      gradient: spec.accentGradient,
                                    ),
                                  ),
                                ),

                                // content
                                Padding(
                                  padding: EdgeInsets.fromLTRB(14.w + 6.w, 12.h, 12.w, 12.h),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34.w, height: 34.w,
                                        decoration: BoxDecoration(
                                          color: spec.iconBg,
                                          borderRadius: BorderRadius.circular(10.r),
                                          border: Border.all(color: spec.iconStroke),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(spec.icon, size: 18.sp, color: spec.iconColor),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          widget.message,
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1B1B1B),
                                          ),
                                        ),
                                      ),
                                      if (widget.actionText != null) ...[
                                        SizedBox(width: 8.w),
                                        TextButton(
                                          onPressed: () {
                                            widget.onAction?.call();
                                            _dismiss();
                                          },
                                          child: Text(
                                            widget.actionText!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800,
                                              color: spec.actionColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _Spec _specFor(KorraNoticeType t) {
    switch (t) {
      case KorraNoticeType.success:
        return _Spec(
          icon: Icons.check_rounded,
          iconColor: const Color(0xFF1B5E20),
          iconBg: const Color(0xFFEAF4EC),
          iconStroke: const Color(0xFFD3E5D7),
          actionColor: const Color(0xFF1B5E20),
          accentGradient: const LinearGradient(colors: [Color(0xFF1DB954), Color(0xFF71E39D)]),
        );
      case KorraNoticeType.info:
        return _Spec(
          icon: Icons.info_outline_rounded,
          iconColor: KorraColors.brand,
          iconBg: const Color(0xFFF6F1ED),
          iconStroke: const Color(0xFFEAE6E2),
          actionColor: KorraColors.brand,
          accentGradient: const LinearGradient(colors: [Color(0xFFA54600), Color(0xFFD77C32)]),
        );
      case KorraNoticeType.warning:
        return _Spec(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFF7A4E00),
          iconBg: const Color(0xFFFEF4E6),
          iconStroke: const Color(0xFFF4E2C7),
          actionColor: const Color(0xFF7A4E00),
          accentGradient: const LinearGradient(colors: [Color(0xFFFFC46A), Color(0xFFFFA726)]),
        );
      case KorraNoticeType.error:
        return _Spec(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFB3261E),
          iconBg: const Color(0xFFFDEBEC),
          iconStroke: const Color(0xFFF6C9CD),
          actionColor: const Color(0xFFB3261E),
          accentGradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF7043)]),
        );
    }
  }
}

class _Spec {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color iconStroke;
  final Color actionColor;
  final Gradient accentGradient;
  _Spec({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconStroke,
    required this.actionColor,
    required this.accentGradient,
  });
}
