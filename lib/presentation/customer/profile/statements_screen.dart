import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart'; // For grouping
import 'package:iconsax/iconsax.dart'; // Premium Icons

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/transaction_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/models/customer/payment_receipt_data.dart';
import '../../shared/widgets/korra_header.dart';
import '../plans/widgets/empty_state_card.dart';

class StatementsScreen extends StatefulWidget {
  final CustomerRepository repo;
  final String customerUid;

  const StatementsScreen({
    super.key,
    required this.repo,
    required this.customerUid,
  });

  @override
  State<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends State<StatementsScreen> {
  String _filter = 'All'; // Options: All, Money In, Money Out

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "Statements", showLeadingIcon: true),
      body: Column(
        children: [
          // 1. FILTER CHIPS
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Row(
              children: [
                _FilterChip(label: "All", selected: _filter == 'All', onTap: () => setState(() => _filter = 'All')),
                SizedBox(width: 10.w),
                _FilterChip(label: "Money In", selected: _filter == 'Money In', onTap: () => setState(() => _filter = 'Money In')),
                SizedBox(width: 10.w),
                _FilterChip(label: "Money Out", selected: _filter == 'Money Out', onTap: () => setState(() => _filter = 'Money Out')),
              ],
            ),
          ),

          // 2. TRANSACTION LIST
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: widget.repo.streamLedger(widget.customerUid), // Ensure you have this stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
                }

                final rawList = snapshot.data ?? [];

                // A. Apply Filter
                final filteredList = rawList.where((tx) {
                  if (_filter == 'Money In') return tx.amount > 0;
                  if (_filter == 'Money Out') return tx.amount < 0;
                  return true;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: EmptyStateCard(text: "No transactions found"));
                }

                // B. Group By Date (Premium List Style)
                final grouped = groupBy(filteredList, (TransactionModel tx) {
                  return DateFormat('yyyy-MM-dd').format(tx.createdAt);
                });

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 40.h),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final transactions = grouped[dateKey]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateHeader(dateStr: dateKey),
                        ...transactions.map((tx) => _TransactionTile(transaction: tx)),
                        SizedBox(height: 12.h), // Spacing between groups
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount >= 0;
    
    // Premium Styling Logic
    final color = isCredit ? const Color(0xFF027A48) : const Color(0xFF101828); // Green vs Dark Blue
    final sign = isCredit ? "+" : ""; 
    final icon = isCredit ? Iconsax.arrow_circle_down : Iconsax.arrow_circle_up; // In vs Out
    final iconBg = isCredit ? const Color(0xFFECFDF3) : const Color(0xFFF2F4F7);
    final iconColor = isCredit ? const Color(0xFF027A48) : const Color(0xFF344054);

    final amountStr = NumberFormat("#,##0.00", "en_US").format(transaction.amount.abs());

    return InkWell(
      onTap: () {
        // ✅ SMART NAVIGATION LOGIC
        PaymentReceiptData receiptData;

        if (transaction.receiptData != null && transaction.receiptData!.isNotEmpty) {
          // 1. New System: Use the saved receipt snapshot (Perfect Data)
          receiptData = PaymentReceiptData.fromJson(transaction.receiptData!);
        } else {
          // 2. Legacy System: Construct a partial receipt (Safe Fallback)
          receiptData = PaymentReceiptData.fromPartial(
            amount: transaction.amount.abs(),
            date: transaction.createdAt,
            title: transaction.description,
            reference: transaction.reference,
            status: transaction.status.toUpperCase(),
          );
        }

        Get.toNamed(
          Routes.customerTransactionReceipt, 
          arguments: receiptData
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22.sp, color: iconColor),
            ),
            SizedBox(width: 16.w),
            
            // Description & Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description.isNotEmpty ? transaction.description : "System Transaction",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp, 
                      fontWeight: FontWeight.w600, 
                      color: const Color(0xFF101828)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('h:mm a').format(transaction.createdAt),
                    style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085)),
                  ),
                ],
              ),
            ),

            // Amount (Using Plus Jakarta Sans for premium numbers)
            Text(
              "$sign₦$amountStr",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp, 
                fontWeight: FontWeight.w700, 
                color: color
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String dateStr;
  const _DateHeader({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    String label;
    if (check == today) {
      label = "Today";
    } else if (check == yesterday) {
      label = "Yesterday";
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    // Cleaner Header: No background, just crisp text
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11.sp, 
          fontWeight: FontWeight.w700, 
          color: const Color(0xFF98A2B3),
          letterSpacing: 1.0
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? KorraColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: selected ? KorraColors.brand : const Color(0xFFE4E7EC),
            width: 1.5
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }
}