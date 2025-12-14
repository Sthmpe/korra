import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/customer_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../shared/widgets/korra_header.dart'; // Assuming you have this
import '../../shared/notify/korra_notify.dart';
import '../topup_screen.dart';

class LimitUpgradeScreen extends StatefulWidget {
  final Customer customer;
  final CustomerRepository repo;
  final double currentTotalLimit; 
  final double activeDebt; 

  const LimitUpgradeScreen({
    super.key,
    required this.customer,
    required this.repo,
    required this.currentTotalLimit,
    required this.activeDebt,
  });

  @override
  State<LimitUpgradeScreen> createState() => _LimitUpgradeScreenState();
}

class _LimitUpgradeScreenState extends State<LimitUpgradeScreen> {
  final TextEditingController _targetCtrl = TextEditingController();
  final _fmt = NumberFormat("#,##0", "en_US");

  bool _hasActivePlans = false;
  bool _isLoading = true;
  
  // Calculation State
  double _requiredDeposit = 0.0;
  double _targetLimit = 0.0;
  bool _canUpgradeWithCurrentBalance = false;

 // 1. Define the Natural Limit Getter (What they qualify for RIGHT NOW)
  double get _currentNaturalTotalLimit {
     final currentWallet = widget.customer.availableBalance;
     // Old Res = Total - Debt
     final oldRes = (widget.currentTotalLimit - widget.activeDebt).clamp(0.0, double.infinity);
     
     // Formula: (Wallet * 1.25) + (0.25 * OldRes) + Debt
     final newRes = (currentWallet * 1.25) + (oldRes * 0.25);
     final total = newRes + widget.activeDebt;
     
     // Cap at 100k
     return total > 100000 ? 100000 : total;
  }

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    // 1. Check DB for active plans
    final hasPlans = await widget.repo.hasActivePlans(widget.customer.uid);
    
    setState(() {
      _hasActivePlans = hasPlans;
      _isLoading = false;

      // 2. SMART DEFAULT LOGIC
      // Instead of "+ 10,000", we calculate what they actually get based on their wallet.
      
      double startValue = _currentNaturalTotalLimit;

      // Edge Case: If their Natural Limit is barely different from Current (e.g. ₦0 wallet),
      // we actally WANT to show a higher number so they see the "Deposit Required" box appear.
      // Otherwise, it looks like nothing is happening.
      if (startValue <= widget.currentTotalLimit) {
         startValue = widget.currentTotalLimit + 5000; // Nudge them to upgrade by at least 5k
      }

      _targetCtrl.text = _fmt.format(startValue);
      
      // 3. Run the math to update the UI state (_requiredDeposit, buttons, etc.)
      _calculateRequiredDeposit(startValue);
    });
  }

  // 1. Define Constants
  double get _oldReservationLimit => (widget.currentTotalLimit - widget.activeDebt).clamp(0.0, double.infinity);


  void _calculateRequiredDeposit(double targetTotal) {
    // A. Constraint: You can't target lower than your CURRENT ACTUAL limit
    // (e.g. If I have 15k limit, I can't ask for 10k)
    if (targetTotal < widget.currentTotalLimit) {
      targetTotal = widget.currentTotalLimit;
      // Visual feedback update (optional, usually handled by text controller logic below)
    }

    // B. Check if they ALREADY qualify
    // If the target is within their "Natural Limit" (based on current wallet), 
    // they don't need to add money.
    if (targetTotal <= _currentNaturalTotalLimit) {
      setState(() {
        _targetLimit = targetTotal;
        _requiredDeposit = 0;
        _canUpgradeWithCurrentBalance = true; // Button becomes "Apply Now"
        
        // We show them the MAXIMUM they can get for free (Natural Limit) 
        // so they don't shortchange themselves.
        if (targetTotal < _currentNaturalTotalLimit) {
           _targetLimit = _currentNaturalTotalLimit;
           _targetCtrl.text = _fmt.format(_targetLimit);
        }
      });
      return;
    }

    // C. Calculate EXTRA Deposit needed for the HIGHER target
    // TargetTotal = ( (CurrentWallet + EXTRA) * 1.25 ) + (0.25 * OldRes) + Debt
    // ... Algebra ...
    // EXTRA = [ (TargetTotal - Debt - (0.25 * OldRes)) / 1.25 ] - CurrentWallet

    final debt = widget.activeDebt;
    final currentWallet = widget.customer.availableBalance;

    double numerator = targetTotal - debt - (0.25 * _oldReservationLimit);
    double totalWalletNeeded = numerator / 1.25;
    double extraDeposit = totalWalletNeeded - currentWallet;

    setState(() {
      _targetLimit = targetTotal;
      _requiredDeposit = extraDeposit > 0 ? extraDeposit : 0;
      _canUpgradeWithCurrentBalance = false; // They need to fund wallet
    });
  }

  void _onTargetChanged(String val) {
    String clean = val.replaceAll(',', '');
    double target = double.tryParse(clean) ?? 0;
    
    // Cap at 500k
    if (target > 500000) target = 500000;
    
    _calculateRequiredDeposit(target);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: KorraColors.brand)));
    }

    // --- STATE 1: BLOCKED ---
    if (_hasActivePlans) {
      return Scaffold(
        appBar: const KorraHeader(title: "Upgrade Limit", showLeadingIcon: true),
        body: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: Icon(Iconsax.lock, size: 40.sp, color: Colors.orange.shade800),
              ),
              SizedBox(height: 24.h),
              Text(
                "Upgrade Locked",
                style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12.h),
              Text(
                "You currently have an active plan. To unlock higher limits, please complete your current plan first. This builds your trust score.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14.sp, height: 1.5, color: Colors.grey.shade600),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text("Go Back"),
                ),
              )
            ],
          ),
        ),
      );
    }

    // --- STATE 2: UNLOCKED (CALCULATOR) ---
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "Upgrade Limit", showLeadingIcon: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CURRENT STATUS
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current Limit", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                      SizedBox(height: 4.h),
                      Text("₦${_fmt.format(widget.currentTotalLimit)}", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text("Active", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 2. THE "WISH" INPUT
            Text("I want a limit of...", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            SizedBox(height: 12.h),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: KorraColors.brand),
              decoration: InputDecoration(
                prefixText: "₦ ",
                prefixStyle: GoogleFonts.inter(fontSize: 32.sp, fontWeight: FontWeight.w800, color: Colors.grey.shade400),
                border: InputBorder.none,
                hintText: "0",
              ),
              onChanged: _onTargetChanged,
            ),
            Divider(color: Colors.grey.shade200, thickness: 1.5),

            SizedBox(height: 32.h),

            // 3. THE REQUIREMENT CARD
            if (_canUpgradeWithCurrentBalance)
               _buildSuccessCard()
            else
               _buildRequirementCard(),

            SizedBox(height: 40.h),

            // 4. ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: FilledButton(
                onPressed: () async {
                   if (_canUpgradeWithCurrentBalance) {
                      // TRIGGER RECALCULATION
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing upgrade...")));
                        await widget.repo.recalculateLimit(widget.customer.uid);
                        Get.back();
                        KorraNotify.success(context, "Limit Upgraded Successfully!");
                      } catch (e) {
                        KorraNotify.error(context, e.toString());
                      }
                   } else {
                      // GO TO FUNDING
                      Get.to(() => TopUpScreen(customer: widget.customer));
                   }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _canUpgradeWithCurrentBalance ? const Color(0xFF0F172A) : KorraColors.brand,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text(
                  _canUpgradeWithCurrentBalance ? "Unlock Now" : "Fund ₦${_fmt.format(_requiredDeposit)}",
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            
            if (!_canUpgradeWithCurrentBalance) ...[
               SizedBox(height: 16.h),
               Center(
                 child: Text(
                   "Deposited funds remain yours to spend.",
                   style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                 ),
               ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.blue.shade700),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Deposit Required", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.blue.shade800)),
                SizedBox(height: 4.h),
                Text(
                  "₦${_fmt.format(_requiredDeposit)}",
                  style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF059669)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You are eligible!", style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF065F46))),
                SizedBox(height: 4.h),
                Text(
                  "Your current wallet balance covers this upgrade.",
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF064E3B)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}