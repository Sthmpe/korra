part of 'vendor_activity_timeline.dart';

class _VendorActivityTilePro extends StatefulWidget {
  final VendorActivity item;
  final bool isFirst;
  final bool isLast;

  final void Function(VendorActivity)? onOpenReservation;
  final void Function(VendorActivity)? onAdjustStock;
  final void Function(VendorActivity)? onViewPlan;

  const _VendorActivityTilePro({
    required this.item,
    required this.isFirst,
    required this.isLast,
    this.onOpenReservation,
    this.onAdjustStock,
    this.onViewPlan,
  });

  @override
  State<_VendorActivityTilePro> createState() => _VendorActivityTileProState();
}

class _VendorActivityTileProState extends State<_VendorActivityTilePro>
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
          // timeline rail + node (same as customer)
          SizedBox(
            width: 24.w,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!widget.isFirst)
                  Positioned(
                    top: -8.h, bottom: 24.h,
                    child: Container(width: 2.w, color: const Color(0xFFE9E5E2)),
                  ),
                if (!widget.isLast)
                  Positioned(
                    top: 24.h, bottom: -8.h,
                    child: Container(width: 2.w, color: const Color(0xFFE9E5E2)),
                  ),
                Container(
                  width: 24.w, height: 24.w,
                  decoration: BoxDecoration(
                    color: spec.bg, shape: BoxShape.circle,
                    border: Border.all(color: spec.stroke),
                  ),
                  alignment: Alignment.center,
                  child: Icon(spec.icon, size: 14.sp, color: spec.fg),
                ),
              ],
            ),
          ),

          // bubble
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
                    Text(widget.item.title,
                      style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1B))),
                    SizedBox(height: 4.h),
                    Text(widget.item.subtitle,
                      style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E5E5E))),

                    AnimatedCrossFade(
                      firstChild: SizedBox(height: 4.h),
                      secondChild: Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Wrap(
                          spacing: 8.w, runSpacing: 8.h,
                          children: _actionsFor(widget.item),
                        ),
                      ),
                      crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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

  List<Widget> _actionsFor(VendorActivity a) {
    switch (a.type) {
      case VendorActivityType.newReservation:
        return [
          if (widget.onOpenReservation != null)
            _primary('Open reservation', () => widget.onOpenReservation!(a)),
        ];
      case VendorActivityType.paymentMissed:
        return [
          if (widget.onViewPlan != null)
            _primary('View plan', () => widget.onViewPlan!(a)),
        ];
      case VendorActivityType.lowStock:
        return [
          if (widget.onAdjustStock != null)
            _primary('Adjust stock', () => widget.onAdjustStock!(a)),
        ];
      case VendorActivityType.info:
        return const [];
    }
  }

  _Spec _specFor(VendorActivityType t) {
    switch (t) {
      case VendorActivityType.newReservation:
        return const _Spec(
          icon: Icons.link_rounded,
          fg: _brand,
          bg: Color(0xFFF6F1ED),
          stroke: Color(0xFFEAE6E2),
        );
      case VendorActivityType.paymentMissed:
        return const _Spec(
          icon: Icons.warning_amber_rounded,
          fg: Color(0xFF7A4E00),
          bg: Color(0xFFFEF4E6),
          stroke: Color(0xFFF4E2C7),
        );
      case VendorActivityType.lowStock:
        return const _Spec(
          icon: Icons.remove,
          fg: Color(0xFF5E5E5E),
          bg: Color(0xFFF3F2F1),
          stroke: Color(0xFFE3E3E3),
        );
      case VendorActivityType.info:
        return const _Spec(
          icon: Icons.info_outline,
          fg: Color(0xFF5E5E5E),
          bg: Color(0xFFF3F2F1),
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
        child: Text(text,
          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white)),
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
