// lib/presentation/customer/storefront/widgets/storefront_reviews_section.dart
//
// One store review card — used by StoreReviewsScreen. (This file used to hold
// the whole bottom-sheet reviews section; the full experience now lives in
// lib/presentation/customer/storefront/store_reviews_screen.dart.)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/vendor_review.dart';

class StoreReviewCard extends StatelessWidget {
  final VendorReview review;

  const StoreReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final initial =
        review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : 'A';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        //border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer avatar (initial in a soft brand circle)
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4ED),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.brand,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: KorraColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 13.sp,
                          );
                        }),
                        SizedBox(width: 6.w),
                        Text(
                          DateFormat.yMMMd().format(review.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              review.comment,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: KorraColors.textBody,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
