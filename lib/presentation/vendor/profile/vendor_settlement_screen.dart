// lib/presentation/vendor/profile/vendor_settlement_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

// REPO & MODELS
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/models/vendor/transaction_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "Settlements", showLeadingIcon: true),
      body: Column(
        children: [
          // 1. STATS
          StreamBuilder<VendorStats?>(
            stream: widget.repo.streamVendorStats(widget.vendorUid),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? VendorStats.empty(); 
              
              return Container(
                height: 115.h,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    _StatsCard(
                      label: "Total Earnings",
                      amount: stats.totalEarnings,
                      icon: Iconsax.wallet_money,
                      color: Colors.green,
                    ),
                    SizedBox(width: 12.w),
                    _StatsCard(
                      label: "Vault (Locked)",
                      amount: stats.activeLocks,
                      icon: Iconsax.lock,
                      color: const Color(0xFF175CD3),
                    ),
                    SizedBox(width: 12.w),
                    _StatsCard(
                      label: "Store Credits",
                      amount: stats.totalLiability,
                      icon: Iconsax.card,
                      color: const Color(0xFFB42318),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. FILTER TABS
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FilterTab(
                  label: "Cash Ledger", 
                  isSelected: _filter == 'Cash', 
                  onTap: () => setState(() => _filter = 'Cash')
                ),
                _FilterTab(
                  label: "Store Credits", 
                  isSelected: _filter == 'Store Credit', 
                  onTap: () => setState(() => _filter = 'Store Credit')
                ),
              ],
            ),
          ),

          // 3. LIST
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final Stream<List<TransactionModel>> targetStream;
    
    if (_filter == 'Store Credit') {
      targetStream = widget.repo.streamLiabilityLedger(widget.vendorUid);
    } else {
      targetStream = widget.repo.streamCashLedger(widget.vendorUid);
    }

    return StreamBuilder<List<TransactionModel>>(
      stream: targetStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.receipt_1, size: 48.sp, color: Colors.grey.shade300),
                SizedBox(height: 12.h),
                Text("No records found", style: GoogleFonts.inter(color: Colors.grey)),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 8.h, bottom: 40.h),
          itemCount: transactions.length,
          separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return _VendorTransactionTile(
              transaction: tx, 
              isLiability: _filter == 'Store Credit'
            );
          },
        );
      },
    );
  }
}

// ... _StatsCard and _FilterTab remain identical ... 
class _StatsCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat("#,##0.00", "en_US");
    return Container(
      width: 155.w,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label, 
                  style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "₦${fmt.format(amount)}",
            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA54600) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ✅ UPDATED TILE TO PASS FULL MODEL
class _VendorTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool isLiability;

  const _VendorTransactionTile({required this.transaction, required this.isLiability});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount >= 0;
    Color amountColor;
    IconData icon;
    Color iconBg;

    if (isLiability) {
      if (isPositive) {
        amountColor = const Color(0xFFB42318);
        icon = Iconsax.add_circle;
        iconBg = const Color(0xFFFEF3F2);
      } else {
        amountColor = const Color(0xFF16A34A);
        // ✅ Fixed Typo: minus_cirlce -> minus_circle
        icon = Iconsax.minus_cirlce; 
        iconBg = const Color(0xFFECFDF5);
      }
    } else {
      if (isPositive) {
        amountColor = const Color(0xFF16A34A);
        icon = Iconsax.arrow_down;
        iconBg = const Color(0xFFECFDF5);
      } else {
        amountColor = Colors.redAccent;
        icon = Icons.arrow_upward;
        iconBg = Colors.redAccent.shade100.withOpacity(0.2);
      }
    }

    return InkWell(
      onTap: () {
        // ✅ FIX: Navigation points to VendorReceiptScreen
        // We pass the entire 'transaction' model now.
        Get.toNamed(
          Routes.vendorReceipt,
          arguments: {'transaction': transaction},
        );
      },
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 20.sp, color: amountColor),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160.w,
                    child: Text(
                      transaction.description,
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('MMM d, h:mm a').format(transaction.createdAt),
                    style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isPositive ? '+' : '-'}₦${NumberFormat("#,##0.00", "en_US").format(transaction.amount.abs())}",
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: amountColor),
                ),
                if (transaction.reference.isNotEmpty && transaction.reference != 'null')
                  Text(
                    transaction.reference.length > 10 
                      ? "...${transaction.reference.substring(transaction.reference.length - 8)}" 
                      : transaction.reference,
                    style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}