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
                  if (_filter == 'Money In') return tx.amount >= 0;
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
                        ...transactions.map((tx) => _TransactionTile(tx: tx)),
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
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");
    final isCredit = tx.amount >= 0; 
    var amountStr = currencyFormat.format(tx.amount.abs());
    final sign = isCredit ? "+" : "-";

    // 1. PREMIUM DEFAULT STYLING
    String displayTitle = "System Transaction";
    String displaySubtitle = tx.description;
    
    // 🚀 NEW ICONS (Material Rounded) & PREMIUM RED
    IconData icon = isCredit ? Icons.call_received_rounded : Icons.call_made_rounded;
    Color iconColor = isCredit ? const Color(0xFF027A48) : const Color(0xFF344054);
    Color iconBg = isCredit ? const Color(0xFFECFDF3) : const Color(0xFFF2F4F7);
    
    // 🚀 Premium Red for Money Out
    Color amountColor = isCredit ? const Color(0xFF027A48) : const Color(0xFF344054); 

    // 2. EXTRACT RECEIPT DATA FOR SPLIT PAYMENTS
    Map<String, dynamic> receiptMap = tx.receiptData ?? {};

    // 3. 🚀 THE SMART SWITCH: Match Backend Types
    switch (tx.type) {
      case 'deposit':
        displayTitle = "Wallet Funded";
        displaySubtitle = "Bank Transfer";
        icon = Icons.account_balance_wallet_outlined;;
        iconBg = const Color(0xFFE0F2FE); // Light Blue
        iconColor = const Color(0xFF026AA2); // Dark Blue
        break;

      case 'plan_creation':
        displayTitle = "Plan Downpayment";
        icon = Icons.shopping_bag_outlined;
        // 🚀 Check for split payment
        final walletUsed = receiptMap['walletUsed'] ?? 0.0;
        final creditUsed = receiptMap['creditUsed'] ?? 0.0;
        if (creditUsed > 0 && walletUsed > 0) {
          displaySubtitle = "₦${currencyFormat.format(walletUsed)} Wallet + ₦${currencyFormat.format(creditUsed)} Store Credit";
        } else if (creditUsed > 0) {
          displaySubtitle = "Paid fully with Store Credit";
        }
        break;

      case 'installment':
        displayTitle = "Plan Payment";
        icon = Icons.credit_card_outlined;
        final wUsed = receiptMap['walletUsed'] ?? 0.0;
        final cUsed = receiptMap['creditUsed'] ?? 0.0;
        if (cUsed > 0 && wUsed > 0) {
          displaySubtitle = "₦${currencyFormat.format(wUsed)} Wallet + ₦${currencyFormat.format(cUsed)} Store Credit";
        } else if (cUsed > 0) {
          displaySubtitle = "Paid fully with Store Credit";
        }
        break;

      case 'plan_cancelled':
      case 'refund':
        displayTitle = "Refund Secured";
        amountStr = currencyFormat.format(tx.convertedAmount); // Show the full refunded amount
        displaySubtitle = tx.description.isNotEmpty ? tx.description : "Moved to Store Balance";
        icon = Icons.shield_outlined;
        iconBg = const Color(0xFFFEF0C7); // Light Orange/Gold
        iconColor = const Color(0xFFDC6803);
        amountColor = const Color(0xFFDC6803);
        break;
    }

    return InkWell(
      onTap: () {
        PaymentReceiptData receiptData;

        if (tx.receiptData != null && tx.receiptData!.isNotEmpty) {
          receiptData = PaymentReceiptData.fromJson(tx.receiptData!);
        } else {
          receiptData = PaymentReceiptData.fromPartial(
            amount: tx.amount.abs(),
            date: tx.createdAt,
            title: tx.description,
            reference: tx.reference,
            status: tx.status.toUpperCase(),
          );
        }

        // 🚀 WE PASS THE TYPE AS AN ARGUMENT NOW
        Get.toNamed(
          Routes.customerTransactionReceipt, 
          arguments: {
            'data': receiptData,
            'type': tx.type,
            'convertedAmount': tx.convertedAmount, // Pass the converted amount for refunds
          }
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 22.sp, color: iconColor),
            ),
            SizedBox(width: 16.w),
            
            // Description & Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    displaySubtitle,
                    style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount 
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$sign₦$amountStr",
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.sp, fontWeight: FontWeight.w700, color: amountColor),
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormat('MMM d, h:mm a').format(tx.createdAt),
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
            color: selected ? KorraColors.brand : const Color(0xFFE4E7EC).withOpacity(0.35),
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