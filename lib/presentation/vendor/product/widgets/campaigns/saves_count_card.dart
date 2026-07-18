// lib/presentation/vendor/product/widgets/campaigns/saves_count_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../config/constants/colors.dart';

/// "Saves" — how many customers have saved this store (customers/{uid}/
/// my_vendors/{vendorId}). Counted live with a collectionGroup aggregate so it
/// moves BOTH ways: up when a customer saves, down when they unsave — no
/// maintained counter to drift. Borderless premium design; number is shown
/// TikTok/Instagram style (raw under 1,000, one-decimal K/M above).
class SavesCountCard extends StatefulWidget {
  final String vendorId;

  const SavesCountCard({super.key, required this.vendorId});

  @override
  State<SavesCountCard> createState() => _SavesCountCardState();
}

class _SavesCountCardState extends State<SavesCountCard> {
  late Future<int> _savesFuture;

  @override
  void initState() {
    super.initState();
    _savesFuture = _fetchSaves();
  }

  Future<int> _fetchSaves() async {
    try {
      final agg = await FirebaseFirestore.instance
          .collectionGroup('my_vendors')
          .where('vendorId', isEqualTo: widget.vendorId)
          .count()
          .get();
      return agg.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 342 -> "342", 1200 -> "1.2K", 15300 -> "15.3K", 1500000 -> "1.5M".
  /// Trailing ".0" is dropped so exact thousands read "1K", not "1.0K".
  static String compact(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) return '${_trim(n / 1000)}K';
    return '${_trim(n / 1000000)}M';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C0D00).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Iconsax.archive_book,
                size: 18.sp, color: const Color(0xFFA54600)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Saves",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Customers who saved your store",
                  style: GoogleFonts.inter(
                    fontSize: 10.5.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          FutureBuilder<int>(
            future: _savesFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 18.w,
                  width: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFA54600),
                  ),
                );
              }
              return Text(
                compact(snap.data ?? 0),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.textDark,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
