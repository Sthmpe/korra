import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/customer/activity_item.dart';
import 'customer_repository.dart';

extension CustomerActivityFeed on CustomerRepository {
  
  // Formatter
  NumberFormat get _currencyFormat => NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  // Styles (Defined here as requested, though usually belongs in UI)
  TextStyle get _baseStyle => GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E5E5E));
  TextStyle get _boldStyle => GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700);

  Stream<List<ActivityItem>> streamActivityFeed(String uid) {
    return streamLedger(uid).map((transactions) {
      
      List<ActivityItem> feed = [];

      for (var tx in transactions) {
        final isCredit = tx.type == 'deposit';
        final amountValue = tx.amount.abs();
        final formattedAmount = _currencyFormat.format(amountValue);
        
        // Prepare the trailing amount string (+ or -)
        String amountDisplay = isCredit ? "+ $formattedAmount" : "- $formattedAmount";

        ActivityType type;
        String title;
        List<TextSpan> richSubtitle;

        // Colors
        final highlightColor = isCredit ? const Color(0xFF16A34A) : const Color(0xFFA54600); 
        final highlightStyle = _boldStyle.copyWith(color: highlightColor);

        switch (tx.type) {
          case 'deposit':
            type = ActivityType.autopay; // Using autopay icon for wallet
            title = "Wallet Top-up";
            richSubtitle = [
              TextSpan(text: "Successfully credited ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " to your wallet.", style: _baseStyle),
            ];
            break;

          case 'down_payment':
            type = ActivityType.payment;
            title = "Reservation Secured";
            richSubtitle = [
              TextSpan(text: "You paid ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " upfront to secure the plan.", style: _baseStyle),
            ];
            break;

          case 'repayment':
            type = ActivityType.payment;
            title = "Installment Paid";
            richSubtitle = [
              TextSpan(text: "Repayment of ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " applied to your plan.", style: _baseStyle),
            ];
            break;

          case 'cancellation':
            type = ActivityType.expired;
            title = "Plan Cancellation";
            richSubtitle = [
              TextSpan(text: "Plan cancelled. Refund of ", style: _baseStyle),
              TextSpan(text: formattedAmount, style: highlightStyle),
              TextSpan(text: " is processing.", style: _baseStyle),
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
        ));
      }
      
      return feed;
    });
  }
}