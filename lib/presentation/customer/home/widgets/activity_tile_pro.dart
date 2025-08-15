part of 'activity_timeline.dart';


class _ActivityTilePro extends StatefulWidget {
  final ActivityItem item;
  final bool isFirst;
  final bool isLast;

  final void Function(ActivityItem)? onPayNow;
  final void Function(ActivityItem)? onViewPlan;
  final void Function(ActivityItem)? onViewReceipt;
  final void Function(ActivityItem)? onReviewLink;
  final void Function(ActivityItem)? onEnableAutopay;

  const _ActivityTilePro({
    required this.item,
    required this.isFirst,
    required this.isLast,
    this.onPayNow,
    this.onViewPlan,
    this.onViewReceipt,
    this.onReviewLink,
    this.onEnableAutopay,
  });

  @override
  State<_ActivityTilePro> createState() => _ActivityTileProState();
}

class _ActivityTileProState extends State<_ActivityTilePro>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(widget.item.type);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail + node
          SizedBox(
            width: 24.w,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // rail above
                if (!widget.isFirst)
                  Positioned(
                    top: -8.h,
                    bottom: 24.h,
                    child: Container(width: 2.w, color: const Color(0xFFE9E5E2)),
                  ),
                // rail below
                if (!widget.isLast)
                  Positioned(
                    top: 24.h,
                    bottom: -8.h,
                    child: Container(width: 2.w, color: const Color(0xFFE9E5E2)),
                  ),
                // node
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: spec.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: spec.stroke),
                  ),
                  alignment: Alignment.center,
                  child: Icon(spec.icon, size: 14.sp, color: spec.fg),
                ),
              ],
            ),
          ),

          // Bubble
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFEAE6E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.item.title,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B1B),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Subtitle/meta
                    Text(
                      widget.item.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5E5E5E),
                      ),
                    ),

                    // Actions (expand to reveal)
                    AnimatedCrossFade(
                      firstChild: SizedBox(height: 4.h),
                      secondChild: Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _actionsFor(widget.item),
                        ),
                      ),
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 160),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(ActivityItem a) {
    switch (a.type) {
      case ActivityType.payment:
        return [
          if (widget.onViewReceipt != null)
            _primary('View receipt', () => widget.onViewReceipt!(a)),
          if (widget.onViewPlan != null)
            _secondary('View plan', () => widget.onViewPlan!(a)),
        ];
      case ActivityType.dueSoon:
        return [
          if (widget.onPayNow != null)
            _primary('Pay now', () => widget.onPayNow!(a)),
          if (widget.onViewPlan != null)
            _secondary('View plan', () => widget.onViewPlan!(a)),
        ];
      case ActivityType.link:
        return [
          if (widget.onReviewLink != null)
            _primary('Review link', () => widget.onReviewLink!(a)),
        ];
      case ActivityType.autopay:
        return [
          if (widget.onEnableAutopay != null)
            _primary('Enable AutoPay', () => widget.onEnableAutopay!(a)),
          if (widget.onViewPlan != null)
            _secondary('View plan', () => widget.onViewPlan!(a)),
        ];
      case ActivityType.expired:
        return [
          if (widget.onViewPlan != null)
            _primary('View plan', () => widget.onViewPlan!(a)),
        ];
    }
  }

  _Spec _specFor(ActivityType t) {
    switch (t) {
      case ActivityType.payment:
        return const _Spec(
          icon: Icons.check_rounded,
          fg: Color(0xFF1B5E20),
          bg: Color(0xFFEAF4EC),
          stroke: Color(0xFFD3E5D7),
        );
      case ActivityType.dueSoon:
        return const _Spec(
          icon: Icons.warning_amber_rounded,
          fg: Color(0xFF7A4E00),
          bg: Color(0xFFFEF4E6),
          stroke: Color(0xFFF4E2C7),
        );
      case ActivityType.link:
        return const _Spec(
          icon: Icons.link_rounded,
          fg: _brand,
          bg: Color(0xFFF6F1ED),
          stroke: Color(0xFFEAE6E2),
        );
      case ActivityType.autopay:
        return const _Spec(
          icon: Icons.autorenew_rounded,
          fg: Color(0xFF1A237E),
          bg: Color(0xFFE8EAF6),
          stroke: Color(0xFFD7DAEC),
        );
      case ActivityType.expired:
        return const _Spec(
          icon: Icons.timer_off_rounded,
          fg: Color(0xFF5E5E5E),
          bg: Color(0xFFF2F2F2),
          stroke: Color(0xFFE3E3E3),
        );
    }
  }

  Widget _primary(String text, VoidCallback onTap) {
    return SizedBox(
      height: 36.h,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFA54600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  Widget _secondary(String text, VoidCallback onTap) {
    return SizedBox(
      height: 36.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEAE6E2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          foregroundColor: const Color(0xFFA54600),
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Spec {
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color stroke;
  const _Spec({required this.icon, required this.fg, required this.bg, required this.stroke});
}
