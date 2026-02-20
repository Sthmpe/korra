// lib/data/repository/customer/customer_activity_feed.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/customer/activity_item.dart';
import 'customer_repository.dart';

extension CustomerActivityFeed on CustomerRepository {
  
  NumberFormat get _currencyFormat => NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  // Premium Typography
  TextStyle get _baseStyle => GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E5E5E));
  TextStyle get _boldStyle => GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828));

  Stream<List<ActivityItem>> streamActivityFeed(String uid) {
    // We listen to the Ledger because it is the Source of Truth for money movement
    return streamLedger(uid).map((transactions) {
      
      List<ActivityItem> feed = [];

      for (var tx in transactions) {
        final isCredit = tx.amount >= 0; // Money coming in (Refunds/Deposits)
        final amountValue = tx.amount.abs();
        final formattedAmount = _currencyFormat.format(amountValue);
        
        String amountDisplay = isCredit ? "+ $formattedAmount" : "- $formattedAmount";

        ActivityType type;
        String title;
        List<TextSpan> richSubtitle;

        // Styles specific to transaction direction
        final highlightColor = isCredit ? const Color(0xFF16A34A) : const Color(0xFFA54600); 
        final highlightStyle = _boldStyle.copyWith(color: highlightColor);

        // ✅ MATCH BACKEND TYPES
        switch (tx.type) {
          case 'deposit': // Wallet Funding
            type = ActivityType.autopay; 
            title = "Wallet Funded";
            richSubtitle = [
              TextSpan(text: "Successfully credited ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " to your wallet.", style: _baseStyle),
            ];
            break;

          case 'plan_creation': // Down Payment
            type = ActivityType.payment;
            title = "Reservation Secured";
            richSubtitle = [
              TextSpan(text: "You made an Initial Deposit of ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " to activate your plan. ", style: _baseStyle),
            ];
            break;

          case 'installment': // Regular Payment
            type = ActivityType.payment;
            title = "Payment Received";
            richSubtitle = [
              TextSpan(text: "Payment of ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " applied to your plan.", style: _baseStyle),
            ];
            break;

          case 'Plan Closed': // Plan Cancelled -> Money moves to Wallet
            type = ActivityType.autopay; 
            title = "Funds Secured"; // High Status: Sounds safe and intentional
            richSubtitle = [
              TextSpan(text: "Value of ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " moved to Store Balance.", style: _baseStyle),
            ];
            break;

          default:
            type = ActivityType.link;
            title = "System Activity";
            richSubtitle = [TextSpan(text: tx.description, style: _baseStyle)];
        }

        feed.add(ActivityItem(
          id: tx.id,
          title: title,
          richSubtitle: richSubtitle,
          amountDisplay: amountDisplay,
          date: tx.createdAt,
          amount: tx.amount,
          type: type,
          planId: tx.planId,
          receiptData: tx.receiptData, // ✅ Passing the suitcase
        ));
      }
      
      return feed;
    });
  }
}