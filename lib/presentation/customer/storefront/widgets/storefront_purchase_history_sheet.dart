import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/customer/plans.dart';

class StorefrontPurchaseHistorySheet extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String vendorId;
  final String storeName;
  final String customerUid;
  final ScrollController scrollController;

  StorefrontPurchaseHistorySheet({
    super.key,
    required this.vendorId,
    required this.storeName,
    required this.customerUid,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Modal Drag Handle
        Container(
          margin: EdgeInsets.symmetric(vertical: 12.h),
          width: 36.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),

        // Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(Iconsax.receipt_item, color: KorraColors.brand, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "My Purchases - $storeName",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: KorraColors.borderLight, height: 1),

        // List of Orders
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('plans')
                .where('customerId', isEqualTo: customerUid)
                .where('vendorId', isEqualTo: vendorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.receipt_item, size: 40.sp, color: KorraColors.textHint),
                        SizedBox(height: 12.h),
                        Text(
                          "No purchases yet",
                          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Any orders you make with $storeName will show up here.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12.sp, color: KorraColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final plans = docs.map((doc) => Plan.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

              return ListView.builder(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

                  return Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(color: KorraColors.borderLight, width: 0.5.w),
                    ),
                    elevation: 0,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12.r),
                      leading: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: Colors.grey.shade50,
                          border: Border.all(color: KorraColors.borderLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: plan.imageUrls.isNotEmpty
                              ? Image.network(
                                  plan.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Iconsax.image, size: 20.sp, color: Colors.grey),
                                )
                              : Icon(Iconsax.image, size: 20.sp, color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: plan.status == 'completed'
                                    ? KorraColors.successBg
                                    : KorraColors.brandLight,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                plan.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: plan.status == 'completed'
                                      ? KorraColors.successFg
                                      : KorraColors.brand,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "${currencyFormat.format(plan.amountPaid)} / ${currencyFormat.format(plan.totalAmount)}",
                              style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: KorraColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      trailing: Icon(Iconsax.arrow_right_3, size: 16.sp, color: KorraColors.textHint),
                      onTap: () {
                        Navigator.pop(context); // Close sheet
                        Get.toNamed(Routes.customerPlanDetailsLoader, arguments: {'planId': plan.id});
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
