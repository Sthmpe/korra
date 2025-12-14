import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart'; // For grouping

import '../../../../data/models/customer/transaction_model.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../shared/widgets/korra_header.dart';
import '../plans/widgets/empty_state_card.dart';
import '../plans/widgets/transaction_receipt_screen.dart';

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
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
            child: Row(
              children: [
                _FilterChip(
                  label: "All", 
                  selected: _filter == 'All', 
                  onTap: () => setState(() => _filter = 'All')
                ),
                SizedBox(width: 8.w),
                _FilterChip(
                  label: "Money In", 
                  selected: _filter == 'Money In', 
                  onTap: () => setState(() => _filter = 'Money In')
                ),
                SizedBox(width: 8.w),
                _FilterChip(
                  label: "Money Out", 
                  selected: _filter == 'Money Out', 
                  onTap: () => setState(() => _filter = 'Money Out')
                ),
              ],
            ),
          ),

          // 2. TRANSACTION LIST
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: widget.repo.streamLedger(widget.customerUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)));
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

                // B. Group By Date (Engineering Magic 🪄)
                // Creates a Map: {"2023-10-25": [Tx1, Tx2], "2023-10-24": [Tx3]}
                final grouped = groupBy(filteredList, (TransactionModel tx) {
                  return DateFormat('yyyy-MM-dd').format(tx.createdAt);
                });

                return ListView.builder(
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
    final color = isCredit ? const Color(0xFF16A34A) : const Color(0xFF1B1B1B);
    final sign = isCredit ? "+" : ""; // Negative numbers already have - in the model usually, but formatting handles it
    
    // Format amount strictly
    final amountStr = NumberFormat("#,##0.00", "en_US").format(transaction.amount.abs());

    return InkWell(
      onTap: () {
        // NAVIGATE TO RECEIPT
        // We reuse the nice receipt screen we built earlier
        Get.to(() => TransactionReceiptScreen(
          amount: transaction.amount.abs(),
          planName: transaction.description, // Mapping description to plan name area
          date: transaction.createdAt,
        ));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 20.sp,
                color: isCredit ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
              ),
            ),
            SizedBox(width: 16.w),
            
            // Description & Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? "System Transaction",
                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('h:mm a').format(transaction.createdAt),
                    style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              "$sign₦$amountStr",
              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: color),
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      color: const Color(0xFFF9FAFB), // Section divider color
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF98A2B3)),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA54600) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: selected ? const Color(0xFFA54600) : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF344054),
          ),
        ),
      ),
    );
  }
}