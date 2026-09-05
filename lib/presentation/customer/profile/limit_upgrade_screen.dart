import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../config/constants/colors.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/notify/korra_notify.dart';

/// Account tiers ("Level Up Slots"): swipe through tiers, see progress toward
/// the next one, upgrade when eligible. Premium redesign 5 July 2026 — the
/// carousel is height-flexible (the old fixed 460.h risked RenderFlex
/// overflows) and the upgrade flow uses guarded pops.
class LimitUpgradeScreen extends StatefulWidget {
  final Customer customer;
  final int currentMaxSlots;
  final int completedPlansCount;

  const LimitUpgradeScreen({
    super.key,
    required this.customer,
    required this.currentMaxSlots,
    required this.completedPlansCount,
  });

  @override
  State<LimitUpgradeScreen> createState() => _LimitUpgradeScreenState();
}

class _LimitUpgradeScreenState extends State<LimitUpgradeScreen> {
  late PageController _pageCtrl;
  int _currentIndex = 0;
  bool _upgrading = false;
  bool _celebrating = false;

  // --- CONFIG: matches the tier names in the Customer model ---
  final List<_TierConfig> _tiers = [
    _TierConfig(
      name: "Starter",
      slots: 3,
      reqPlans: 0,
      color: const Color(0xFF475569),
      gradient: const [Color(0xFF64748B), Color(0xFF475569)],
      icon: Iconsax.user,
    ),
    _TierConfig(
      name: "Keeper",
      slots: 5,
      reqPlans: 3,
      color: const Color(0xFF2563EB),
      gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      icon: Iconsax.shield_tick,
    ),
    _TierConfig(
      name: "Collector",
      slots: 10,
      reqPlans: 10,
      color: const Color(0xFF7C3AED),
      gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      icon: Iconsax.box,
    ),
    _TierConfig(
      name: "VIP",
      slots: 999,
      reqPlans: 25,
      color: const Color(0xFFD97706),
      gradient: const [Color(0xFFF59E0B), Color(0xFFB45309)],
      icon: Iconsax.crown,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Land on the next attainable tier.
    int initialPage =
        _tiers.indexWhere((t) => t.slots > widget.currentMaxSlots);
    if (initialPage == -1) {
      initialPage = _tiers.indexWhere((t) => t.slots == widget.currentMaxSlots);
    }
    _currentIndex = initialPage.clamp(0, _tiers.length - 1);
    _pageCtrl =
        PageController(viewportFraction: 0.85, initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTier = _tiers[_currentIndex];

    return Scaffold(
      backgroundColor: KorraColors.surface,
      appBar: const KorraHeader(title: "Level Up Slots", showLeadingIcon: true),
      body: Stack(
        children: [
          Column(
        children: [
          SizedBox(height: 10.h),

          // 1. HEADER STATS
          _buildUserStats(),

          SizedBox(height: 12.h),

          // 2. TIER CAROUSEL — flexible height so it can never overflow.
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (index) {
                HapticFeedback.selectionClick(); // tactile, game-like swipe
                setState(() => _currentIndex = index);
              },
              itemCount: _tiers.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final selected = _currentIndex == index;
                return AnimatedScale(
                  scale: selected ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: selected ? 1.0 : 0.55,
                    duration: const Duration(milliseconds: 300),
                    child: _buildTierCard(_tiers[index]),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12.h),

          // 3. PAGE DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_tiers.length, (i) {
              final active = _currentIndex == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 18.w : 6.w,
                height: 6.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active
                      ? _tiers[_currentIndex].color
                      : const Color(0xFFD0D5DD),
                ),
              );
            }),
          ),

          SizedBox(height: 12.h),

          // 4. SMART ACTION BUTTON
          _buildActionZone(activeTier),
        ],
          ),

          // 5. CELEBRATION BURST — brief, on a successful upgrade only.
          if (_celebrating)
            Positioned.fill(
              child: IgnorePointer(
                child: _ConfettiBurst(color: activeTier.color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCol("${widget.currentMaxSlots}", "Active Slots"),
          ),
          Container(height: 30.h, width: 1, color: const Color(0xFFF2F4F7)),
          Expanded(
            child: _statCol(
                "${widget.completedPlansCount}", "Completed Plans"),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String value, String label) {
    final target = int.tryParse(value) ?? 0;
    return Column(
      children: [
        // Ticks up from 0 on first build, arcade-scoreboard style.
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: target),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Text(
            "$value",
            style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: KorraColors.textDark),
          ),
        ),
        SizedBox(height: 2.h),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: KorraColors.textMuted)),
      ],
    );
  }

  Widget _buildTierCard(_TierConfig tier) {
    final bool isCurrent = tier.slots == widget.currentMaxSlots;
    final bool isPassed = widget.currentMaxSlots > tier.slots;
    final bool isLocked =
        widget.completedPlansCount < tier.reqPlans && !isCurrent && !isPassed;

    double progress = tier.reqPlans > 0
        ? (widget.completedPlansCount / tier.reqPlans).clamp(0.0, 1.0)
        : 1.0;
    if (isPassed) progress = 1.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: isLocked
                ? Colors.black.withValues(alpha: 0.05)
                : tier.color.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Gradient header with the tier badge
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 26.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLocked
                    ? [Colors.grey.shade400, Colors.grey.shade600]
                    : tier.gradient,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isLocked ? Iconsax.lock : tier.icon,
                      size: 32.sp, color: Colors.white),
                ),
                SizedBox(height: 12.h),
                Text(
                  tier.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.r, 18.r, 20.r, 18.r),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tier.slots >= 999 ? "∞" : "${tier.slots}",
                        style: GoogleFonts.inter(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w900,
                            color: KorraColors.textDark,
                            height: 1.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 7.h, left: 4.w),
                        child: Text("slots",
                            style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: KorraColors.textMuted)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tier.reqPlans == 0
                        ? "Everyone starts here"
                        : "Complete ${tier.reqPlans} plans to qualify",
                    style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: KorraColors.textMuted),
                  ),

                  const Spacer(),

                  if (isCurrent)
                    _statusPill(Icons.check_circle, "CURRENT LEVEL",
                        const Color(0xFFECFDF5), const Color(0xFF039855))
                  else if (isLocked) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Progress",
                            style: GoogleFonts.inter(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: KorraColors.textMuted)),
                        Text("${(progress * 100).toInt()}%",
                            style: GoogleFonts.inter(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: KorraColors.textDark)),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      // Charges up from empty each time this card renders,
                      // like an XP bar filling rather than a static state.
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          backgroundColor: const Color(0xFFF2F4F7),
                          color: tier.color,
                          minHeight: 6.h,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "${tier.reqPlans - widget.completedPlansCount} more plan${tier.reqPlans - widget.completedPlansCount == 1 ? '' : 's'} to unlock",
                      style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: tier.color),
                    ),
                  ] else if (isPassed)
                    _statusPill(Icons.check, "UNLOCKED",
                        const Color(0xFFF2F4F7), KorraColors.textMuted)
                  else
                    // Eligible but not yet upgraded — this should feel like
                    // a reward waiting to be claimed, not a done state.
                    _statusPill(Icons.auto_awesome, "READY TO UPGRADE",
                        tier.color.withValues(alpha: 0.12), tier.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: color),
          SizedBox(width: 6.w),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionZone(_TierConfig tier) {
    final bool isCurrent = tier.slots == widget.currentMaxSlots;
    final bool isLower = tier.slots < widget.currentMaxSlots;
    final bool isEligible = widget.completedPlansCount >= tier.reqPlans;

    String btnText = "Locked";
    Color btnColor = const Color(0xFFF2F4F7);
    Color txtColor = KorraColors.textHint;
    VoidCallback? onTap;

    if (isCurrent) {
      btnText = "Current Level";
    } else if (isLower) {
      btnText = "Unlocked";
    } else if (!isEligible) {
      btnText =
          "Complete ${tier.reqPlans - widget.completedPlansCount} More Plans";
    } else {
      btnText = "Upgrade to ${tier.name}";
      btnColor = tier.color;
      txtColor = Colors.white;
      onTap = _upgrading ? null : () => _processUpgrade(tier);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            disabledBackgroundColor: btnColor,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _upgrading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(btnText,
                  style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: txtColor)),
        ),
      ),
    );
  }

  Future<void> _processUpgrade(_TierConfig tier) async {
    // Inline button spinner instead of a dialog — the old double
    // Navigator.pop across the await was our known navigator-wedge pattern.
    HapticFeedback.mediumImpact();
    setState(() => _upgrading = true);
    try {
      await context
          .read<CustomerRepository>()
          .upgradeTier(widget.customer.uid, tier.name);
      if (!mounted) return;
      // Reward beat: a brief confetti burst on this same screen (no new
      // route/dialog, so the existing pop below stays a single, safe pop).
      HapticFeedback.heavyImpact();
      setState(() {
        _upgrading = false;
        _celebrating = true;
      });
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      Navigator.pop(context); // close this screen only
      KorraNotify.success(context, "Welcome to the ${tier.name} Tier! 🚀");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _upgrading = false;
        _celebrating = false;
      });
      KorraNotify.error(context, e.toString());
    }
  }
}

class _TierConfig {
  final String name;
  final int slots;
  final int reqPlans;
  final Color color;
  final List<Color> gradient;
  final IconData icon;

  const _TierConfig({
    required this.name,
    required this.slots,
    required this.reqPlans,
    required this.color,
    required this.gradient,
    required this.icon,
  });
}

/// Lightweight reward-moment burst: a handful of small shapes launch from
/// screen center and fall away while fading, no external package needed.
/// Purely decorative and self-disposing — it never blocks input.
class _ConfettiBurst extends StatefulWidget {
  final Color color;

  const _ConfettiBurst({required this.color});

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _particleColors = [
    Color(0xFFA54600),
    Color(0xFFF59E0B),
    Color(0xFF2563EB),
    Color(0xFF039855),
    Color(0xFFD92D20),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    final rand = math.Random();
    _particles = List.generate(22, (i) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 80 + rand.nextDouble() * 140;
      return _Particle(
        angle: angle,
        speed: speed,
        size: 5 + rand.nextDouble() * 6,
        color: _particleColors[i % _particleColors.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return CustomPaint(
          painter: _ConfettiPainter(particles: _particles, progress: t),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final fade = (1.0 - progress).clamp(0.0, 1.0);
    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * progress;
      // Gravity: particles fall faster than they rise/spread outward.
      final dy = math.sin(p.angle) * p.speed * progress + 260 * progress * progress;
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawCircle(center + Offset(dx, dy), p.size * fade.clamp(0.3, 1.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
