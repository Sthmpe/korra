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
import '../../../../data/models/vendor/outright_order.dart';
import 'storefront_lazy_image.dart';

/// Unified purchase entry rendered in the history list — built from either a
/// `plans` document (Reservation) or an `orders` document (Outright Purchase).
class _PurchaseEntry {
  final bool isOutright;
  final String title;
  final String imageUrl;
  final String statusLabel;
  final Color statusBg;
  final Color statusFg;
  final String amountText;
  final DateTime? date;
  final VoidCallback? onTap;

  _PurchaseEntry({
    required this.isOutright,
    required this.title,
    required this.imageUrl,
    required this.statusLabel,
    required this.statusBg,
    required this.statusFg,
    required this.amountText,
    required this.date,
    this.onTap,
  });
}

/// Purchase history for one storefront, merging layaway **Reservations**
/// (`plans` collection) and **Outright Purchases** (`orders` collection),
/// each labelled with its type.
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
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),

        // Title
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.receipt_item, color: KorraColors.brand, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Purchases",
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: KorraColors.textDark,
                      ),
                    ),
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: KorraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: KorraColors.borderLight, height: 1),

        // Merged Reservations + Outright Orders
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('plans')
                .where('customerId', isEqualTo: customerUid)
                .where('vendorId', isEqualTo: vendorId)
                .snapshots(),
            builder: (context, planSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('orders')
                    .where('customerId', isEqualTo: customerUid)
                    .where('vendorId', isEqualTo: vendorId)
                    .snapshots(),
                builder: (context, orderSnapshot) {
                  final bothWaiting =
                      planSnapshot.connectionState == ConnectionState.waiting &&
                          orderSnapshot.connectionState == ConnectionState.waiting;
                  if (bothWaiting) {
                    return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
                  }

                  final entries = [
                    ..._planEntries(context, planSnapshot.data?.docs ?? []),
                    ..._orderEntries(orderSnapshot.data?.docs ?? []),
                  ];

                  if (entries.isEmpty) return _buildEmptyState();

                  // Newest first; undated entries sink to the bottom
                  entries.sort((a, b) {
                    if (a.date == null && b.date == null) return 0;
                    if (a.date == null) return 1;
                    if (b.date == null) return -1;
                    return b.date!.compareTo(a.date!);
                  });

                  return ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: entries.length,
                    itemBuilder: (context, index) => _PurchaseTile(entry: entries[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── plans/ → Reservation entries ──────────────────────────────────────────
  List<_PurchaseEntry> _planEntries(BuildContext context, List<QueryDocumentSnapshot> docs) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final plan = Plan.fromMap(data, doc.id);
      final completed = plan.status == 'completed';

      return _PurchaseEntry(
        isOutright: false,
        title: plan.title,
        imageUrl: plan.imageUrls.isNotEmpty ? plan.imageUrls.first : '',
        statusLabel: plan.status.toUpperCase(),
        statusBg: completed ? KorraColors.successBg : KorraColors.brandLight,
        statusFg: completed ? KorraColors.successFg : KorraColors.brand,
        amountText:
            "${currencyFormat.format(plan.amountPaid)} / ${currencyFormat.format(plan.totalAmount)}",
        date: (data['createdAt'] as Timestamp?)?.toDate(),
        onTap: () {
          Navigator.pop(context); // Close sheet
          Get.toNamed(Routes.customerPlanDetailsLoader, arguments: {'planId': plan.id});
        },
      );
    }).toList();
  }

  // ── orders/ → Outright Purchase entries ───────────────────────────────────
  List<_PurchaseEntry> _orderEntries(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final order = OutrightOrder.fromFirestore(doc);
      final first = order.items.isNotEmpty ? order.items.first : null;
      final extra = order.items.length - 1;

      final Color bg;
      final Color fg;
      if (order.isDelivered) {
        bg = KorraColors.successBg;
        fg = KorraColors.successFg;
      } else if (order.isCancelled) {
        bg = const Color(0xFFFEF3F2);
        fg = const Color(0xFFB42318);
      } else {
        bg = KorraColors.brandLight;
        fg = KorraColors.brand;
      }

      return _PurchaseEntry(
        isOutright: true,
        title: first == null
            ? "Outright Order"
            : (extra > 0 ? "${first.title} +$extra more" : first.title),
        imageUrl: first?.imageUrl ?? '',
        statusLabel: order.isDelivered
            ? "DELIVERED"
            : order.isCancelled
                ? "CANCELLED"
                : order.isReadyToDeliver
                    ? "READY TO DELIVER"
                    : "PROCESSING",
        statusBg: bg,
        statusFg: fg,
        amountText: order.totalText,
        date: order.createdAt,
      );
    }).toList();
  }

  Widget _buildEmptyState() {
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
              style: GoogleFonts.inter(
                  fontSize: 14.sp, fontWeight: FontWeight.w700, color: KorraColors.textDark),
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
}

/// Single purchase row with the type chip (Reservation vs Outright).
class _PurchaseTile extends StatelessWidget {
  final _PurchaseEntry entry;

  const _PurchaseTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: entry.onTap,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: SizedBox(
                      width: 54.w,
                      height: 54.w,
                      child: entry.imageUrl.isNotEmpty
                          ? StorefrontLazyImage(url: entry.imageUrl, memCacheWidth: 150)
                          : Container(
                              color: const Color(0xFFF4F5F7),
                              child: Icon(Iconsax.image, size: 18.sp, color: Colors.grey),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: KorraColors.textDark,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Purchase type chip: Reservation vs Outright
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: entry.isOutright
                                    ? const Color(0xFFECFDF3)
                                    : const Color(0xFFFFF4ED),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                entry.isOutright ? "OUTRIGHT" : "RESERVATION",
                                style: GoogleFonts.inter(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: entry.isOutright
                                      ? KorraColors.settleGreen
                                      : KorraColors.brand,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: entry.statusBg,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                entry.statusLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: entry.statusFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          entry.amountText,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: KorraColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.onTap != null)
                    Icon(Iconsax.arrow_right_3, size: 16.sp, color: KorraColors.textHint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}