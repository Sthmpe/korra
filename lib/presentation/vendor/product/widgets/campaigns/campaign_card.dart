// lib/presentation/vendor/product/widgets/campaigns/campaign_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../config/constants/colors.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../data/models/vendor/campaign_model.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;

  /// Multi-select delete support: when [selectionMode] is on, tapping the
  /// card toggles [selected]; otherwise tapping opens the campaign's
  /// analytics sheet (the caller decides — [onTap] fires either way).
  /// Long-pressing a card while not yet in selection mode is how the
  /// merchant enters selection.
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Quick single delete, shown as a trash icon when not in selection mode.
  final VoidCallback? onDeleteTap;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.selectionMode = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = campaign.isActive;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(
          color: selected ? const Color(0xFFA54600) : const Color(0xFFF2F4F7),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image (Compulsory)
          if (campaign.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(KorraSizes.cardRadius.r)),
              child: Image.network(
                campaign.imageUrl,
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120.h,
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag + Date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Tag Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4ED),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            campaign.tag.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFA54600),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Active/Expired status badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: active ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            active ? "ACTIVE" : "EXPIRED",
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.green.shade700 : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(campaign.sentAt),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Title (20 chars max in creation)
                Text(
                  campaign.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                
                // Caption (40 chars max, single line only!)
                Text(
                  campaign.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF475467),
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 12.h),
                const Divider(color: Color(0xFFEAECF0)),
                SizedBox(height: 8.h),

                // Stats footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Products link count
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 14.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              campaign.productTitles.join(", "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Opens counter
                    Row(
                      children: [
                        Icon(Icons.touch_app_outlined, size: 14.sp, color: const Color(0xFFA54600)),
                        SizedBox(width: 4.w),
                        Text(
                          "${campaign.openCount} opens",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA54600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

          // Selection checkbox (selection mode) / quick delete (normal mode)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: selectionMode
                ? Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFA54600) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? const Color(0xFFA54600) : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? Icon(Icons.check, size: 15.sp, color: Colors.white)
                        : null,
                  )
                : (onDeleteTap != null
                    ? InkWell(
                        onTap: onDeleteTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline, size: 16.sp, color: const Color(0xFFB42318)),
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
        ],
      ),
      ),
    );
  }
}
