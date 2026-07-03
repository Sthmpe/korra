import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import 'storefront_reviews_section.dart';

class StorefrontHeader extends StatelessWidget {
  final String vendorId;
  final String storeName;
  final String description;
  final String logoUrl;
  final String coverUrl;
  final String phone;
  final String email;
  final dynamic whatsapp;
  final dynamic instagram;
  final dynamic twitter;
  final bool isPinned;
  final VoidCallback onPinToggle;
  final Function(String) onLaunchSocial;

  const StorefrontHeader({
    super.key,
    required this.vendorId,
    required this.storeName,
    required this.description,
    required this.logoUrl,
    required this.coverUrl,
    required this.phone,
    required this.email,
    required this.whatsapp,
    required this.instagram,
    required this.twitter,
    required this.isPinned,
    required this.onPinToggle,
    required this.onLaunchSocial,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Banner
        Container(
          height: 120.h,
          width: double.infinity,
          decoration: BoxDecoration(
            image: coverUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(coverUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: coverUrl.isEmpty
                ? const LinearGradient(
                    colors: [KorraColors.brand, Color(0xFFE05600)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
        ),

        // Brand Row (Avatar & Follow Action)
        Transform.translate(
          offset: Offset(0, -35.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo Avatar
                Container(
                  height: 80.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: logoUrl.isNotEmpty
                        ? Image.network(logoUrl, fit: BoxFit.cover)
                        : Container(
                            color: KorraColors.brandLight,
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: GoogleFonts.inter(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                color: KorraColors.brand,
                              ),
                            ),
                          ),
                  ),
                ),

                // Pin / Follow Action Button
                GestureDetector(
                  onTap: onPinToggle,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isPinned ? Colors.grey.shade100 : const Color(0xFFFFF4ED),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isPinned ? Colors.grey.shade300 : const Color(0xFFFFD1B3),
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
                          isPinned ? "Pinned" : "Pin Store",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isPinned ? Colors.grey.shade700 : const Color(0xFFA54600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Text Meta & Description
        Transform.translate(
          offset: Offset(0, -25.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      storeName,
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: KorraColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                StreamBuilder<QuerySnapshot>(
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

                    if (count == 0) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () => _showStoreReviewsSheet(context, vendorId, storeName),
                      child: Row(
                        children: [
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
                          SizedBox(width: 6.w),
                          Text(
                            "reviews >",
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
                  },
                ),
                SizedBox(height: 8.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: KorraColors.textBody,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 16.h),

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
                    if (twitter != null && twitter.toString().isNotEmpty)
                      _buildSocialChip(
                        icon: FaIcon(FontAwesomeIcons.twitter, size: 14.sp, color: const Color(0xFF1DA1F2)),
                        label: "Twitter",
                        onTap: () => onLaunchSocial("https://twitter.com/${twitter.toString().replaceAll('@', '')}"),
                      ),
                    if (phone.isNotEmpty)
                      _buildSocialChip(
                        icon: Icon(Icons.phone, size: 14.sp, color: KorraColors.brand),
                        label: "Call Us",
                        onTap: () => onLaunchSocial("tel:$phone"),
                      ),
                    if (email.isNotEmpty)
                      _buildSocialChip(
                        icon: Icon(Icons.email, size: 14.sp, color: Colors.blue),
                        label: "Email",
                        onTap: () => onLaunchSocial("mailto:$email"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFFF2F4F7), height: 1),
      ],
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

  void _showStoreReviewsSheet(BuildContext context, String vendorId, String storeName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: StorefrontReviewsSection(vendorId: vendorId),
            );
          },
        );
      },
    );
  }
}
