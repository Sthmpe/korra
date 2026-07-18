import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/outright_order.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

/// Customer-side view of one outright purchase — opened from the purchase
/// history list. Read-only twin of the merchant's order detail sheet: shows
/// the Order ID (copy/share so the customer can send it to the merchant),
/// items, totals and the delivery status. Makes it explicit that "Delivery
/// Processing" is about the merchant marking delivery, NOT about the payment,
/// which completed at checkout.
class CustomerOutrightOrderSheet extends StatelessWidget {
  final OutrightOrder order;
  final String storeName;

  const CustomerOutrightOrderSheet({
    super.key,
    required this.order,
    required this.storeName,
  });

  String get _orderIdShort => order.id.substring(0, 8).toUpperCase();

  void _copyOrderId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: order.id));
    showAppSnackbar("Order ID copied", SnackbarType.success);
  }

  void _shareOrderId() {
    Share.share(
      "Hello $storeName, here is my Korra outright order.\n"
      "Order ID: ${order.id}\n"
      "Items: ${order.items.map((i) => "${i.title} x${i.quantity}").join(', ')}\n"
      "Total paid: ${order.totalText}",
      subject: "Korra Order $_orderIdShort",
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = order;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title + status
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Outright Order",
                          style: GoogleFonts.inter(
                              fontSize: 18.sp, fontWeight: FontWeight.w800)),
                      Text(storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                ),
                _CustomerStatusPill(order: o),
              ],
            ),
          ),

          Divider(height: 32.h, color: Colors.grey.shade100),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ORDER ID (copy + share to merchant) ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ORDER ID",
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(_orderIdShort,
                                  style: GoogleFonts.inter(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5)),
                            ),
                            IconButton(
                              onPressed: () => _copyOrderId(context),
                              icon: Icon(Iconsax.copy,
                                  size: 18.sp, color: KorraColors.brand),
                              tooltip: "Copy Order ID",
                            ),
                            IconButton(
                              onPressed: _shareOrderId,
                              icon: Icon(Iconsax.send_2,
                                  size: 18.sp, color: KorraColors.brand),
                              tooltip: "Share with merchant",
                            ),
                          ],
                        ),
                        Text(
                          "Share this ID with $storeName to reference your order.",
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // --- DELIVERY STATUS EXPLAINER ---
                  _DeliveryStatusCard(order: o),

                  SizedBox(height: 24.h),

                  // --- ITEMS ---
                  Text("ITEMS",
                      style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                          letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  ...o.items.map(_itemRow),

                  SizedBox(height: 24.h),

                  // --- SUMMARY ---
                  Text("SUMMARY",
                      style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                          letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  _row("Total Items", "${o.items.length}"),
                  SizedBox(height: 8.h),
                  _row("Total Paid", o.totalText,
                      valueColor: Colors.green.shade700, bold: true),
                  // Campaign tags active when this order was placed —
                  // snapshot copied at purchase, hidden when there were none.
                  if (o.promotions.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Promotions",
                            style: GoogleFonts.inter(
                                fontSize: 13.sp, color: Colors.grey.shade600)),
                        SizedBox(width: 12.w),
                        Flexible(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: o.promotions
                                .map((tag) => Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDF0E6),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        tag,
                                        style: GoogleFonts.inter(
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFA54600)),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 8.h),
                  _row("Ordered On",
                      DateFormat('MMM d, yyyy - h:mm a').format(o.createdAt)),
                  if (o.deliveredAt != null) ...[
                    SizedBox(height: 8.h),
                    _row("Delivered On",
                        DateFormat('MMM d, yyyy - h:mm a').format(o.deliveredAt!)),
                  ],

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(OutrightOrderItem item) {
    final priceStr =
        "₦${(item.unitPrice * item.quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 13.sp)),
                SizedBox(height: 2.h),
                Text(
                  "Qty: ${item.quantity}  •  ₦${item.unitPrice.toStringAsFixed(0)} each",
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(priceStr,
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade600)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? Colors.black)),
      ],
    );
  }
}

/// Big status card that spells out what "Delivery Processing" actually means:
/// the payment is done, the merchant just hasn't marked the order delivered.
class _DeliveryStatusCard extends StatelessWidget {
  final OutrightOrder order;
  const _DeliveryStatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String title;
    final String message;

    if (o.isDelivered) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF027A48);
      icon = Icons.check_circle;
      title = "Delivered";
      message = "Your merchant has marked this order as delivered. Enjoy!";
    } else if (o.isCancelled) {
      bg = const Color(0xFFFEF3F2);
      fg = const Color(0xFFB42318);
      icon = Icons.cancel_outlined;
      title = "Cancelled";
      message = "This order was cancelled. Contact $_store if you have questions.";
    } else {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFB95000);
      icon = Icons.local_shipping_outlined;
      title = "Delivery Processing";
      message =
          "Your payment is complete — processing only means your merchant hasn't marked this order as delivered yet. If you already received it, share your Order ID and ask them to mark it delivered.";
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: fg),
              SizedBox(width: 8.w),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w800, color: fg)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(message,
              style: GoogleFonts.inter(
                  fontSize: 12.sp, color: Colors.grey.shade700, height: 1.5)),
        ],
      ),
    );
  }

  String get _store => "the store";
}

class _CustomerStatusPill extends StatelessWidget {
  final OutrightOrder order;
  const _CustomerStatusPill({required this.order});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color bg;
    final Color fg;
    if (order.isDelivered) {
      text = "DELIVERED";
      bg = const Color(0xFFECFDF3);
      fg = const Color(0xFF027A48);
    } else if (order.isCancelled) {
      text = "CANCELLED";
      bg = const Color(0xFFFEF3F2);
      fg = const Color(0xFFB42318);
    } else {
      text = "PROCESSING";
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFB95000);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
