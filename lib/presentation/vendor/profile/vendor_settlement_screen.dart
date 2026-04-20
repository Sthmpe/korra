import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

// REPO & MODELS
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/models/vendor/transaction_model.dart';
import '../../../data/models/vendor/vendor_monthly_flow.dart';
import '../../../data/models/vendor/vendor_stat.dart';
import '../../shared/widgets/korra_header.dart';

class VendorSettlementScreen extends StatefulWidget {
  final VendorRepository repo;
  final String vendorUid;

  const VendorSettlementScreen({
    super.key,
    required this.repo,
    required this.vendorUid,
  });

  @override
  State<VendorSettlementScreen> createState() => _VendorSettlementScreenState();
}

class _VendorSettlementScreenState extends State<VendorSettlementScreen> {
  String _filter = 'Cash'; 
  
  // 🚀 INFINITE SCROLL VARIABLES
  final ScrollController _scrollController = ScrollController();
  int _limit = 50;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🚀 DETECT BOTTOM OF LIST AND INCREASE LIMIT
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
          _limit += 50; // Load 50 more
        });
        
        // Reset loading lock after a short delay so it doesn't spam the state
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Very light grey background
      appBar: const KorraHeader(title: "Settlements & Ledger", showLeadingIcon: true),
      body: Column(
        children: [
          // 1. PREMIUM STATS ROW
          // 1. PURE MONTHLY ANALYTICS ROW
          StreamBuilder<VendorMonthlyFlow>(
            stream: widget.repo.streamCurrentMonthStats(widget.vendorUid),
            builder: (context, monthSnapshot) {
              // Default to 0 if no stats exist for the current month yet
              final monthly = monthSnapshot.data ?? VendorMonthlyFlow(earnings: 0, creditIssued: 0, creditRedeemed: 0);

              return Container(
                height: 124.h, 
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // 🚀 This hides the ugly Android overscroll glow/bar
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  children: [
                    // CARD 1: Cash flow IN
                    _StatsCard(
                      label: "Earnings (This Month)", 
                      amount: monthly.earnings,
                      icon: Iconsax.chart_2,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF059669), // Green
                    ),
                    SizedBox(width: 12.w),
                    
                    // CARD 2: Store Balance ISSUED (Refunds to customers)
                    _StatsCard(
                      label: "Store Balance Issued (This Month)", // 🚀 Updated Terminology
                      amount: monthly.creditIssued,
                      icon: Iconsax.export_1,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFDC2626), // Red (Because it's new debt)
                    ),
                    SizedBox(width: 12.w),
                    
                    // CARD 3: Store Balance REDEEMED (Customers spending it)
                    _StatsCard(
                      label: "Store Balance Redeemed (This Month)", // 🚀 Updated Terminology
                      amount: monthly.creditRedeemed,
                      icon: Iconsax.card_tick,
                      iconBg: const Color(0xFFEFF8FF),
                      iconColor: const Color(0xFF175CD3), // Blue (Because debt is cleared)
                    ),
                  ],
                ),
              );
            }
          ),

          // 2. APPLE-STYLE SEGMENTED CONTROL
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentTab(
                      label: "Cash Ledger",
                      isSelected: _filter == 'Cash',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() { _filter = 'Cash'; _limit = 50; });
                      },
                    ),
                  ),
                  Expanded(
                    child: _SegmentTab(
                      label: "Store Balance",
                      isSelected: _filter == 'Store Credit',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() { _filter = 'Store Credit'; _limit = 50; });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. TRANSACTION LIST
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final Stream<List<TransactionModel>> targetStream;
    
    // 🚀 PASS THE DYNAMIC LIMIT TO THE STREAM
    if (_filter == 'Store Credit') {
      targetStream = widget.repo.streamLiabilityLedger(widget.vendorUid, limit: _limit);
    } else {
      targetStream = widget.repo.streamCashLedger(widget.vendorUid, limit: _limit);
    }

    return StreamBuilder<List<TransactionModel>>(
      stream: targetStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _limit == 50) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Iconsax.receipt_1, size: 40.sp, color: Colors.grey.shade300),
                ),
                SizedBox(height: 16.h),
                Text("No transactions yet", style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.builder(
          controller: _scrollController, // 🚀 ATTACH THE CONTROLLER HERE
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.only(top: 12.h, bottom: 40.h),
          itemCount: transactions.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading spinner at the bottom if fetching more
            if (index == transactions.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA54600)))),
              );
            }

            final tx = transactions[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
              child: _VendorTransactionTile(
                transaction: tx, 
                isLiability: _filter == 'Store Credit'
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------
// WIDGETS
// ---------------------------------------------------------

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatsCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat("#,##0.00", "en_US");
    return Container(
      width: 150.w,
      padding: EdgeInsets.fromLTRB(12.r, 12.r, 12.r, 12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        //mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 14.sp, color: iconColor),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label, 
                  style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "₦${fmt.format(amount)}",
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF111111), letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}

class _VendorTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool isLiability;

  const _VendorTransactionTile({required this.transaction, required this.isLiability});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    
    // 🚀 NEW: Check if the transaction is pending T+1 settlement
    final bool isPending = transaction.settlementStatus == 'pending'; 

    Color amountColor;
    IconData icon;
    Color iconBg;

    // Design Logic
    if (isLiability) {
      if (isPositive) {
        amountColor = const Color(0xFFB42318);
        icon = Iconsax.add_circle;
        iconBg = const Color(0xFFFEF3F2);
      } else {
        amountColor = const Color(0xFF059669);
        icon = Iconsax.minus_cirlce; 
        iconBg = const Color(0xFFECFDF5);
      }
    } else {
      if (isPositive) {
        // If it's a sale but pending, make it grey/amber. If cleared, make it green.
        amountColor = isPending ? const Color(0xFF475467) : const Color(0xFF059669);
        icon = isPending ? Iconsax.clock : Iconsax.arrow_down;
        iconBg = isPending ? const Color(0xFFF2F4F7) : const Color(0xFFECFDF5);
      } else {
        amountColor = const Color(0xFFDC2626);
        icon = Iconsax.arrow_up_2; // Export/Withdrawal icon
        iconBg = const Color(0xFFFEF2F2);
      }
    }

    return InkWell(
      onTap: () {
        Get.toNamed(Routes.vendorReceipt, arguments: {'transaction': transaction});
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18.sp, color: amountColor),
            ),
            SizedBox(width: 14.w),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM d, h:mm a').format(transaction.createdAt),
                        style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                      ),
                      // 🚀 SHOW PENDING BADGE
                      if (isPending) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(4.r)),
                          child: Text("Pending", style: GoogleFonts.inter(fontSize: 9.sp, color: const Color(0xFFD97706), fontWeight: FontWeight.w600)),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isPositive ? '+' : '-'}₦${NumberFormat("#,##0.00", "en_US").format(transaction.amount.abs())}",
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: amountColor),
                ),
                if (transaction.reference.isNotEmpty && transaction.reference != 'null') ...[
                  SizedBox(height: 4.h),
                  Text(
                    transaction.reference.length > 10 ? "...${transaction.reference.substring(transaction.reference.length - 8)}" : transaction.reference,
                    style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}