// lib/data/models/customer/activity_item.dart

import 'package:flutter/material.dart';

enum ActivityType { payment, dueSoon, link, autopay, expired, milestone }

class ActivityItem {
  final String id;
  final String title;
  
  // Rich Text for "You paid N5,000..."
  final List<TextSpan> richSubtitle; 
  
  // Simple string for "- ₦5,000"
  final String amountDisplay; 
  
  final String? planId; 
  final DateTime date; 
  final double amount; 
  final ActivityType type;

  // ✅ NEW: Carry the full receipt snapshot if available
  final Map<String, dynamic>? receiptData;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.richSubtitle,
    required this.amountDisplay,
    required this.date,
    required this.amount,
    required this.type,
    this.planId,
    this.receiptData,
  });
}