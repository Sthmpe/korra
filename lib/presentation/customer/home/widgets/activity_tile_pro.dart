part of 'activity_timeline.dart';

class _ActivityTilePro extends StatefulWidget {
  final ActivityItem item;
  final bool isFirst;
  final bool isLast;

  final void Function(ActivityItem)? onPayNow;
  final void Function(ActivityItem)? onViewPlan;
  final void Function(ActivityItem)? onViewReceipt;

  const _ActivityTilePro({
    required this.item,
    required this.isFirst,
    required this.isLast,
    this.onPayNow,
    this.onViewPlan,
    this.onViewReceipt,
  });

  @override
  State<_ActivityTilePro> createState() => _ActivityTileProState();
}

class _ActivityTileProState extends State<_ActivityTilePro>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

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
                    top: 0,
                    bottom: 40.h,
                    child: Container(
                      width: 2.w,
                      color: const Color(0xFFE9E5E2),
                    ),
                  ),
                // rail below
                if (!widget.isLast)
                  Positioned(
                    top: 20.h, // Starts from center of icon
                    bottom: 0,
                    child: Container(
                      width: 2.w,
                      color: const Color(0xFFE9E5E2),
                    ),
                  ),
                //node
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: spec.bg,
                    shape: BoxShape.circle,
                    //border: Border.all(color: spec.stroke),
                  ),
                  alignment: Alignment.center,
                  child: Icon(spec.icon, size: 14.sp, color: spec.fg),
                ),
              ],
            ),
          ),

          // Bubble
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.fromLTRB(12.r, 0.r, 12.r, 12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: _expanded
                        ? Border.all(color: spec.stroke.withOpacity(0.05), width: 1.5.sp)
                        : Border.all(
                            color: const Color(0xFFEAE6E2).withOpacity(0.05),
                            width: 1.sp,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER & TEXT ---
                      Padding(
                        padding: EdgeInsets.fromLTRB(12.r, 0.r, 12.r, 12.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.item.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      // THE RICH SUBTITLE (Passed from Repo)
                                      RichText(
                                        text: TextSpan(
                                          children: widget.item.richSubtitle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Side: Amount + Time
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (widget.item.amountDisplay.isNotEmpty)
                                      Text(
                                        widget.item.amountDisplay,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              widget.item.amountDisplay
                                                  .contains('+')
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _formatTime(widget.item.date),
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- EXPANDABLE ACTIONS ---
                      // Actions (expand to reveal)
                      AnimatedCrossFade(
                        firstChild: SizedBox(height: 4.h),
                        secondChild: Padding(
                          padding: EdgeInsets.fromLTRB(12.r, 0, 12.r, 12.r),
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
          ),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(ActivityItem a) {
    // Check if the plan associated with the transaction is completed (Hypothetical field)
    //final isCompleted = a.type == ActivityType.payment && a.subtitle.contains("towards plan") && a.amountRemaining <= 0;

    switch (a.title) {
      case 'Reservation Secured':
        return [
          if (widget.onViewPlan != null)
            _primary('View plan', () => widget.onViewPlan!(a)),
          if (widget.onViewReceipt != null)
            _secondary('View receipt', () => widget.onViewReceipt!(a)),
        ];
      case 'Payment Received':
        return [
          if (widget.onViewPlan != null)
            _primary('View plan', () => widget.onViewPlan!(a)),
          if (widget.onViewReceipt != null)
            _secondary('View receipt', () => widget.onViewReceipt!(a)),
        ];
      case 'Wallet Funded':
        return [
          if (widget.onViewReceipt != null)
            _primary('View receipt', () => widget.onViewReceipt!(a)),
        ];
      case 'Plan Closed':
        return [
          if (widget.onViewPlan != null)
            _secondary('View details', () => widget.onViewPlan!(a)),
        ];
      case 'Plan Completed': // Inject this logic after final payment
        return [
          if (widget.onViewReceipt != null)
            _primary(
              'Start New Plan',
              () => widget.onViewReceipt!(a),
            ), // Reusing receipt callback for now
          if (widget.onViewPlan != null)
            _secondary('View history', () => widget.onViewPlan!(a)),
        ];
      default:
        return [];
    }
  }

  _Spec _specFor(ActivityType t) {
    switch (t) {
      case ActivityType.payment:
        return const _Spec(
          icon: Icons.check_rounded,
          fg: Color(0xFF1B5E20),
          bg: Color(0xFFEAF4EC),
          stroke: Color(0xFFBBF7D0),
        );
      case ActivityType.dueSoon:
        return const _Spec(
          icon: Icons.priority_high_rounded,
          fg: Color(0xFFA16207),
          bg: Color(0xFFFEF9C3),
          stroke: Color(0xFFFEF08A),
        );
      case ActivityType.link:
        return const _Spec(
          icon: Icons.link_rounded,
          fg: Color(0xFFA54600),
          bg: Color(0xFFFFF7ED),
          stroke: Color(0xFFFFEDD5),
        );
      case ActivityType.autopay:
        return const _Spec(
          icon: Icons.autorenew_rounded,
          fg: Color(0xFF1A237E),
          bg: Color(0xFFE8EAF6),
          stroke: Color(0xFFD7DAEC),
        );
      default:
        return const _Spec(
          icon: Icons.notifications_none_rounded,
          fg: Color(0xFF475569),
          bg: Color(0xFFF1F5F9),
          stroke: Color(0xFFE2E8F0),
        );
    }
  }
}

Widget _primary(String text, VoidCallback onTap) {
  return SizedBox(
    height: 36.h,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFA54600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
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
        side: BorderSide(color: const Color(0xFFEAE6E2).withOpacity(0.25)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        foregroundColor: const Color(0xFFA54600),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
      ),
    ),
  );
}


class _Spec {
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color stroke;
  const _Spec({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.stroke,
  });
}

String _formatTime(DateTime dt) {
  return DateFormat('h:mm a').format(dt);
}
