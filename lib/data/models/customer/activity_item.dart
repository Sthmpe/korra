import 'package:flutter/material.dart';

enum ActivityType { payment, dueSoon, link, autopay, expired, milestone }

class ActivityItem {
  final String id;
  final String title;
  
  // 1. The Rich Text Spans for the subtitle
  final List<TextSpan> richSubtitle; 
  
  // 2. The Simple Amount string for the trailing side (e.g. "- ₦5,000")
  final String amountDisplay; 
  
  // 3. For navigation logic (to open receipt/plan)
  final String? planId; 
  final DateTime date; // Renamed from timestamp for clarity in UI code
  final double amount; // Raw amount for math if needed

  final ActivityType type;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.richSubtitle,
    required this.amountDisplay,
    required this.date,
    required this.amount,
    required this.type,
    this.planId,
  });
}