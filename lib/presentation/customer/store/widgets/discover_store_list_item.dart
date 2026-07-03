import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

class DiscoverStoreListItem extends StatelessWidget {
  final String vendorId;
  final String name;
  final String description;
  final String logoUrl;
  final String slug;

  const DiscoverStoreListItem({
    super.key,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: KorraColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed('/store/$slug'),
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Shop Avatar
                        Container(
                          height: 48.w,
                          width: 48.w,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: KorraColors.borderLight),
                          ),
                          alignment: Alignment.center,
                          child: ClipOval(
                            child: logoUrl.isNotEmpty
                                ? Image.network(
                                    logoUrl,
                                    width: 44.w,
                                    height: 44.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildFallback(initial),
                                  )
                                : _buildFallback(initial),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Store Copy details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: KorraColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w400,
                                  color: KorraColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Chevron Arrow
                        Icon(
                          Iconsax.arrow_right_3,
                          size: 16.sp,
                          color: KorraColors.textHint,
                        ),
                      ],
                    ),
                    
                    // Product Preview Row StreamBuilder
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('vendorId', isEqualTo: vendorId)
                          .where('status', isEqualTo: 'approved')
                          .limit(3)
                          .snapshots(),
                      builder: (context, prodSnapshot) {
                        if (!prodSnapshot.hasData || prodSnapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final docs = prodSnapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Divider(height: 1.h, color: KorraColors.borderLight),
                            ),
                            Row(
                              children: docs.map((doc) {
                                final prodData = doc.data() as Map<String, dynamic>;
                                final images = List<String>.from(prodData['images'] ?? []);
                                final String imgUrl = images.isNotEmpty ? images.first : '';
                                return Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: Container(
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: KorraColors.borderLight),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: imgUrl.isNotEmpty
                                          ? Image.network(
                                              imgUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: SizedBox(
                                                    width: 14.w,
                                                    height: 14.w,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 1.5.w,
                                                      valueColor: const AlwaysStoppedAnimation<Color>(KorraColors.brand),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) => Icon(Iconsax.image, size: 16.sp, color: Colors.grey),
                                            )
                                          : Icon(Iconsax.image, size: 16.sp, color: Colors.grey),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(String initial) {
    return Container(
      color: KorraColors.brandLight,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: KorraColors.brand,
        ),
      ),
    );
  }
}
