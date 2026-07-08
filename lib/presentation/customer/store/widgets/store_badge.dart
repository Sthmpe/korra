// lib/presentation/customer/store/widgets/store_badge.dart
//
// Customer-facing merchant recognition badges. Earned badges (Top Seller,
// Most Visited) always outrank the paid Highlighted tier in ordering — Korra
// must never look like it is selling the top spot.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/vendor/vendor_visibility.dart';

enum StoreBadgeType { topSeller, mostVisited, highlighted }

extension StoreBadgeTypeX on StoreBadgeType {
  String get label => switch (this) {
        StoreBadgeType.topSeller => 'Top Seller',
        StoreBadgeType.mostVisited => 'Most Visited',
        StoreBadgeType.highlighted => 'Highlighted',
      };

  IconData get icon => switch (this) {
        StoreBadgeType.topSeller => Iconsax.crown_1,
        StoreBadgeType.mostVisited => Iconsax.eye,
        StoreBadgeType.highlighted => Iconsax.star_1,
      };

  Color get color => switch (this) {
        StoreBadgeType.topSeller => const Color(0xFFB54708), // earned gold
        StoreBadgeType.mostVisited => const Color(0xFF026AA2), // earned blue
        StoreBadgeType.highlighted => const Color(0xFF7F56D9), // tier purple
      };
}

/// Ordered badge list for a visibility doc — earned first, Highlighted last.
/// (No customer-facing numbers: reach counts are merchant-only context.)
List<StoreBadgeType> badgesFromVisibility(VendorVisibility? visibility) {
  if (visibility == null) return const [];
  return [
    if (visibility.topSellerCircles > 0) StoreBadgeType.topSeller,
    if (visibility.mostVisitedCircles > 0) StoreBadgeType.mostVisited,
    if (visibility.isHighlighted) StoreBadgeType.highlighted,
  ];
}

/// One small premium badge chip.
class StoreBadgeChip extends StatelessWidget {
  final StoreBadgeType type;
  final bool compact;

  const StoreBadgeChip({super.key, required this.type, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.w : 8.w,
        vertical: compact ? 2.5.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        //border: Border.all(color: type.color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: compact ? 9.sp : 11.sp, color: type.color),
          SizedBox(width: compact ? 3.w : 4.w),
          Text(
            type.label,
            style: GoogleFonts.inter(
              fontSize: compact ? 8.5.sp : 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: type.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live badge row for one merchant, streamed from
/// `vendor_visibility/{vendorId}`. Renders nothing when the merchant carries
/// no badge — absence must never look like a penalty.
class StoreBadgesRow extends StatelessWidget {
  final String vendorId;

  const StoreBadgesRow({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendor_visibility')
          .doc(vendorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final visibility = VendorVisibility.fromFirestore(snapshot.data!);
        return _chips(badgesFromVisibility(visibility));
      },
    );
  }

  Widget _chips(List<StoreBadgeType> badges) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        children: [for (final b in badges) StoreBadgeChip(type: b)],
      ),
    );
  }
}
