import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Vendor Specific Event Types
enum VendorActivityType { 
  newReservation, // Green - Money coming
  payout,         // Blue - Money sent to bank
  stockLow,       // Orange - Action needed
  planCompleted,  // Purple - Ready for pickup
  extended,       // Orange - Reuse stockLow color
  cancelled,      // Red - Revenue lost
  system          // Grey - General info
}

class VendorActivityItem {
  final String id;
  final String title;
  final String subtitle; // Simple string is usually enough for vendors
  final String? amountDisplay; // e.g., "+ ₦50,000"
  
  final String refId; // ID to navigate to (Reservation ID, Product ID, etc.)
  final DateTime date; 
  final VendorActivityType type;

  const VendorActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.amountDisplay,
    required this.refId,
    required this.date,
    required this.type,
  });

  // --- FACTORY: Parse from Firestore ---
  factory VendorActivityItem.fromMap(Map<String, dynamic> map, String id) {
    
    // Helper to parse enum safely
    VendorActivityType parseType(String? t) {
      switch (t) {
        case 'reservation_new': return VendorActivityType.newReservation;
        case 'payment': return VendorActivityType.payout; // Reuse 'payout' (Blue) or make a new 'income' type (Green)
        case 'reservation_extended': return VendorActivityType.extended; // Reuse 'stockLow' (Orange) or make 'extended' type
        case 'reservation_cancel': return VendorActivityType.cancelled;
        case 'payout_success': return VendorActivityType.payout;
        case 'stock_low': return VendorActivityType.stockLow;
        case 'plan_complete': return VendorActivityType.planCompleted;
        default: return VendorActivityType.system;
      }
    }

    return VendorActivityItem(
      id: id,
      title: map['title'] ?? 'New Activity',
      subtitle: map['body'] ?? '',
      amountDisplay: map['amount_display'], // e.g. "₦20,000"
      refId: map['ref_id'] ?? '', // Crucial for navigation
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: parseType(map['type']),
    );
  }
}