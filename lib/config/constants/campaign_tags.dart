// lib/config/constants/campaign_tags.dart
//
// Shared campaign tag vocabulary. Used by the customer marketplace UI
// (hot deals strip, product cards) AND by the merchant campaign creation
// flow, so both sides always speak the same tags.

import 'package:flutter/material.dart';

class KorraCampaignTags {
  KorraCampaignTags._();

  static const String flashDeal = 'FLASH DEAL';
  static const String hotDeal = 'HOT DEAL';
  static const String newArrival = 'NEW ARRIVAL';
  static const String clearance = 'CLEARANCE';
  static const String weekendSale = 'WEEKEND SALE';
  static const String limitedStock = 'LIMITED STOCK';
  static const String freeDelivery = 'FREE DELIVERY';
  static const String bundleOffer = 'BUNDLE OFFER';

  /// Everything a merchant can pick from when creating a campaign.
  static const List<String> all = [
    flashDeal,
    hotDeal,
    newArrival,
    clearance,
    weekendSale,
    limitedStock,
    freeDelivery,
    bundleOffer,
  ];

  /// Tags that mark a product as a "flash deal" for countdown/urgency UI.
  static const Set<String> flashLike = {flashDeal, hotDeal, limitedStock};

  static bool isFlashDeal(String? tag) =>
      tag != null && flashLike.contains(tag.toUpperCase().trim());

  /// Accent color for a tag chip.
  static Color colorFor(String tag) {
    switch (tag.toUpperCase().trim()) {
      case flashDeal:
        return const Color(0xFFD92D20); // urgent red
      case hotDeal:
        return const Color(0xFFE04F16); // ember orange
      case clearance:
        return const Color(0xFF9E0A05); // deep red
      case limitedStock:
        return const Color(0xFFB54708); // amber
      case newArrival:
        return const Color(0xFF026AA2); // blue
      case weekendSale:
        return const Color(0xFF7F56D9); // purple
      case freeDelivery:
        return const Color(0xFF067647); // green
      case bundleOffer:
        return const Color(0xFF175CD3); // royal blue
      default:
        return const Color(0xFFA54600); // brand fallback
    }
  }
}