import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:get/get.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../store/widgets/store_badge.dart';
import 'storefront_location_row.dart';

/// Store meta block under the collapsing cover app bar: rating line,
/// pin/follow action, description and contact chips.
/// (The cover photo and logo now live in [StorefrontSliverAppBar].)
class StorefrontHeader extends StatelessWidget {
  final String vendorId;
  final String storeName;
  final String description;

  /// Merchant walk-in address ("12 Allen Avenue, Ikeja, Lagos").
  /// Empty when the merchant hasn't provided one — no location UI shows.
  final String address;
  final String phone;
  final dynamic whatsapp;
  final dynamic instagram;
  final dynamic tiktok;
  final bool isPinned;
  final VoidCallback onPinToggle;
  final Function(String) onLaunchSocial;

  const StorefrontHeader({
    super.key,
    required this.vendorId,
    required this.storeName,
    required this.description,
    this.address = '',
    required this.phone,
    required this.whatsapp,
    required this.instagram,
    required this.tiktok,
    required this.isPinned,
    required this.onPinToggle,
    required this.onLaunchSocial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recognition badges (Top Seller / Most Visited / Highlighted) —
              // live, so they change as the merchant earns or loses them.
              StoreBadgesRow(vendorId: vendorId),

              // Rating line + Pin action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildRatingLine(context)),
                  SizedBox(width: 12.w),
                  _buildPinButton(),
                ],
              ),
              SizedBox(height: 10.h),

              // Description
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: KorraColors.textBody,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 16.h),

              // Walk-in location (only when the merchant provided an address);
              // tapping reveals the address inline below the chip.
              if (address.trim().isNotEmpty) ...[
                StorefrontLocationRow(address: address),
                SizedBox(height: 12.h),
              ],

              // Contact Links Row
              Wrap(
                spacing: 12.w,
                runSpacing: 10.h,
                children: [
                  if (whatsapp != null && whatsapp.toString().isNotEmpty)
                    _buildSocialChip(
                      icon: FaIcon(FontAwesomeIcons.whatsapp, size: 14.sp, color: const Color(0xFF25D366)),
                      label: "WhatsApp",
                      onTap: () => onLaunchSocial(whatsapp.toString()),
                    ),
                  if (instagram != null && instagram.toString().isNotEmpty)
                    _buildSocialChip(
                      icon: FaIcon(FontAwesomeIcons.instagram, size: 14.sp, color: const Color(0xFFE1306C)),
                      label: "Instagram",
                      onTap: () => onLaunchSocial("https://instagram.com/${instagram.toString().replaceAll('@', '')}"),
                    ),
                  if (tiktok != null && tiktok.toString().isNotEmpty)
                    _buildSocialChip(
                      icon: FaIcon(FontAwesomeIcons.tiktok, size: 14.sp, color: const Color(0xFF010101)),
                      label: "TikTok",
                      onTap: () => onLaunchSocial("https://tiktok.com/@${tiktok.toString().replaceAll('@', '')}"),
                    ),
                  if (phone.isNotEmpty)
                    _buildSocialChip(
                      icon: Icon(Icons.phone, size: 14.sp, color: KorraColors.brand),
                      label: "Call Us",
                      onTap: () => onLaunchSocial("tel:$phone"),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFF2F4F7), height: 1),
      ],
    );
  }

  Widget _buildRatingLine(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('reviews')
          .snapshots(),
      builder: (context, reviewSnapshot) {
        double average = 0.0;
        int count = 0;
        if (reviewSnapshot.hasData && reviewSnapshot.data!.docs.isNotEmpty) {
          count = reviewSnapshot.data!.docs.length;
          double sum = 0.0;
          for (final doc in reviewSnapshot.data!.docs) {
            final rating = (doc.data() as Map<String, dynamic>?)?['rating'] ?? 0.0;
            sum += (rating as num).toDouble();
          }
          average = sum / count;
        }
        return _ratingRow(context, average, count);
      },
    );
  }

  /// Always visible: rated stores show "4.4 ★★★★½ · Reviews >"; unrated
  /// stores show a muted "No reviews yet" that still opens the reviews screen.
  Widget _ratingRow(BuildContext context, double average, int count) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openReviewsScreen(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) ...[
            Text(
              average.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: KorraColors.textDark,
              ),
            ),
            SizedBox(width: 4.w),
            Row(
              children: List.generate(5, (index) {
                final double starValue = index + 1;
                if (average >= starValue) {
                  return Icon(Icons.star_rounded, color: Colors.amber, size: 14.sp);
                } else if (average > index && average < starValue) {
                  return Icon(Icons.star_half_rounded, color: Colors.amber, size: 14.sp);
                } else {
                  return Icon(Icons.star_outline_rounded, color: Colors.amber, size: 14.sp);
                }
              }),
            ),
            SizedBox(width: 4.w),
            Text(
              "($count)",
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: KorraColors.textMuted,
              ),
            ),
          ] else ...[
            Icon(Icons.star_outline_rounded, color: Colors.amber, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              "No reviews yet",
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: KorraColors.textMuted,
              ),
            ),
          ],
          SizedBox(width: 6.w),
          Text(
            "Reviews >",
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFA54600),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewsScreen(BuildContext context) {
    // Named route — raw Navigator.push corrupts GetX's gesture bookkeeping
    // (see Round 8 handover note).
    Get.toNamed(Routes.customerStoreReviews, arguments: {
      'vendorId': vendorId,
      'storeName': storeName,
    });
  }

  Widget _buildPinButton() {
    return GestureDetector(
      onTap: onPinToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isPinned ? Colors.grey.shade100 : const Color(0xFFFFF4ED),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isPinned ? Colors.grey.shade300.withValues(alpha: 0.1): const Color(0xFFFFD1B3).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPinned ? Icons.star : Icons.star_border,
              size: 16.sp,
              color: isPinned ? Colors.grey.shade700 : const Color(0xFFA54600),
            ),
            SizedBox(width: 6.w),
            Text(
              isPinned ? "Saved" : "Save Store",
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isPinned ? Colors.grey.shade700 : const Color(0xFFA54600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialChip({required Widget icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: KorraColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

}