import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../shared/widgets/korra_header.dart';
import '../../shared/notify/korra_notify.dart';

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

  // --- CONFIG: Defined based on your Model Logic ---
  final List<_TierConfig> _tiers = [
    _TierConfig(
      name: "Starter", 
      slots: 3, 
      reqPlans: 0, 
      color: Colors.blueGrey, 
      gradient: [Color(0xFF64748B), Color(0xFF475569)],
      icon: Iconsax.user
    ),
    _TierConfig(
      name: "Keeper", 
      slots: 5, 
      reqPlans: 3, 
      color: Color(0xFF2563EB), 
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      icon: Iconsax.shield_tick
    ),
    _TierConfig(
      name: "Collector", 
      slots: 10, 
      reqPlans: 10, 
      color: Color(0xFF7C3AED), 
      gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      icon: Iconsax.box
    ),
    _TierConfig(
      name: "VIP", // Changed to match your model 'VIP'
      slots: 999, 
      reqPlans: 25, 
      color: Color(0xFFD97706), 
      gradient: [Color(0xFFF59E0B), Color(0xFFB45309)],
      icon: Iconsax.crown
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-scroll to the next attainable tier
    int initialPage = _tiers.indexWhere((t) => t.slots > widget.currentMaxSlots);
    if (initialPage == -1) initialPage = _tiers.indexWhere((t) => t.slots == widget.currentMaxSlots);
    
    _currentIndex = initialPage.clamp(0, _tiers.length - 1);
    _pageCtrl = PageController(viewportFraction: 0.85, initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final activeTier = _tiers[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light grey bg
      appBar: const KorraHeader(title: "Account Tiers", showLeadingIcon: true),
      body: Column(
        children: [
          SizedBox(height: 10.h),
          
          // 1. HEADER STATS
          _buildUserStats(),

          SizedBox(height: 24.h),

          // 2. PREMIUM CARD CAROUSEL
          SizedBox(
            height: 460.h,
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _tiers.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final tier = _tiers[index];
                // Scale Logic
                final double scale = _currentIndex == index ? 1.0 : 0.9;
                final double opacity = _currentIndex == index ? 1.0 : 0.5;
                
                return TweenAnimationBuilder(
                  tween: Tween(begin: scale, end: scale),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: val,
                      child: Opacity(
                        opacity: opacity,
                        child: _buildProTierCard(tier),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Spacer(),

          // 3. SMART ACTION BUTTON
          _buildActionZone(activeTier),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0,5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                "${widget.currentMaxSlots}",
                style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              Text("Active Slots", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
            ],
          ),
          Container(
            height: 30.h, 
            width: 1, 
            color: Colors.grey.shade200, 
            margin: EdgeInsets.symmetric(horizontal: 24.w)
          ),
          Column(
            children: [
              Text(
                "${widget.completedPlansCount}",
                style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              Text("Completed Plans", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProTierCard(_TierConfig tier) {
    final bool isCurrent = tier.slots == widget.currentMaxSlots;
    final bool isLocked = widget.completedPlansCount < tier.reqPlans && !isCurrent;
    
    // XP Calculation
    double progress = 0.0;
    if (tier.reqPlans > 0) {
      progress = (widget.completedPlansCount / tier.reqPlans).clamp(0.0, 1.0);
    } else {
      progress = 1.0; // Starter is always 100%
    }
    
    // If we passed this tier, it's 100%
    if (widget.currentMaxSlots > tier.slots) progress = 1.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h), // Margin for shadow clipping
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: isLocked ? Colors.black.withOpacity(0.05) : tier.color.withOpacity(0.25), 
            blurRadius: 30, 
            offset: const Offset(0, 15)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: Stack(
          children: [
            // 1. Top Gradient Background
            Positioned(
              top: 0, left: 0, right: 0,
              height: 180.h,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLocked ? [Colors.grey.shade400, Colors.grey.shade600] : tier.gradient,
                  ),
                ),
              ),
            ),

            // 2. Icon Badge
            Positioned(
              top: 40.h, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(isLocked ? Iconsax.lock : tier.icon, size: 40.sp, color: Colors.white),
                ),
              ),
            ),

            // 3. Content Body
            Positioned(
              top: 140.h, left: 0, right: 0, bottom: 0,
              child: Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    Text(
                      tier.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp, 
                        fontWeight: FontWeight.w700, 
                        color: isLocked ? Colors.grey : tier.color,
                        letterSpacing: 1.5
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${tier.slots}",
                          style: GoogleFonts.inter(fontSize: 48.sp, fontWeight: FontWeight.w900, color: Colors.black, height: 1.0),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
                          child: Text("Slots", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ),
                      ],
                    ),
                    
                    const Spacer(),

                    // XP Progress Section
                    if (isCurrent)
                      _buildStatusPill(Icons.check_circle, "CURRENT PLAN", Colors.green.shade50, Colors.green)
                    else if (isLocked)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Progress", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                              Text("${(progress * 100).toInt()}%", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.black)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade100,
                              color: tier.color,
                              minHeight: 6.h,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "${tier.reqPlans - widget.completedPlansCount} more plans to unlock",
                            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                        ],
                      )
                    else
                      // Unlocked but not active (Lower tier)
                      _buildStatusPill(Icons.check, "UNLOCKED", Colors.grey.shade50, Colors.grey),
                    
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionZone(_TierConfig tier) {
    // Logic Map:
    // 1. Current Tier -> "Active" (Disabled)
    // 2. Passed Tier (Lower) -> "Unlocked" (Disabled)
    // 3. Future Tier (Locked) -> "Complete X Plans" (Disabled)
    // 4. Future Tier (Unlocked) -> "Upgrade Now" (Active)

    bool isCurrent = tier.slots == widget.currentMaxSlots;
    bool isLower = tier.slots < widget.currentMaxSlots;
    bool isEligible = widget.completedPlansCount >= tier.reqPlans;

    String btnText = "Locked";
    Color btnColor = Colors.grey.shade300;
    Color txtColor = Colors.grey.shade500;
    VoidCallback? onTap;

    if (isCurrent) {
      btnText = "Current Level";
    } else if (isLower) {
      btnText = "Unlocked";
    } else if (!isEligible) {
      btnText = "Complete ${tier.reqPlans - widget.completedPlansCount} More Plans";
    } else {
      // Eligible for upgrade!
      btnText = "Upgrade to ${tier.name}";
      btnColor = tier.color;
      txtColor = Colors.white;
      onTap = () => _processUpgrade(tier);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 32.h),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            elevation: onTap != null ? 8 : 0,
            shadowColor: onTap != null ? btnColor.withOpacity(0.4) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(btnText, style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: txtColor)),
        ),
      ),
    );
  }

  Future<void> _processUpgrade(_TierConfig tier) async {
    try {
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white))
      );

      // ✅ Update the TIER NAME (String), not just the slot number
      await context.read<CustomerRepository>().upgradeTier(widget.customer.uid, tier.name);

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close screen
      KorraNotify.success(context, "Welcome to the ${tier.name} Tier! 🚀");
    } catch (e) {
      Navigator.pop(context);
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

  _TierConfig({required this.name, required this.slots, required this.reqPlans, required this.color, required this.gradient, required this.icon});
}