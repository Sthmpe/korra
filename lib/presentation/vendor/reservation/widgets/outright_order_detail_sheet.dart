// lib/presentation/vendor/reservation/widgets/outright_order_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/vendor/outright_order.dart';
import '../../../../logic/services/analytics_service.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_bloc.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_event.dart';
import '../../../../logic/bloc/vendor/outright_order/outright_orders_state.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class OutrightOrderDetailSheet extends StatefulWidget {
  final OutrightOrder order;

  const OutrightOrderDetailSheet({
    super.key,
    required this.order,
  });

  @override
  State<OutrightOrderDetailSheet> createState() => _OutrightOrderDetailSheetState();
}

class _OutrightOrderDetailSheetState extends State<OutrightOrderDetailSheet> {
  Future<void> _launchCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanPhone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showAppSnackbar("Could not open phone dialer", SnackbarType.error);
      }
    }
  }

  Future<void> _launchWhatsapp(String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // wa.me needs the international form: 0803... → 234803...
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = '234${cleanPhone.substring(1)}';
    }
    final Uri uri = Uri.parse("https://wa.me/$cleanPhone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        showAppSnackbar("Could not open WhatsApp", SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    // Web orders whose payment Monnify hasn't confirmed yet are visible but
    // not actionable: no delivery until the money is verified.
    final bool awaitingPayment = o.isAwaitingPayment;
    final bool isReady = !awaitingPayment &&
        (o.status == OutrightOrderStatus.readyToDeliver || o.status == OutrightOrderStatus.pending);
    final bool isDelivered = o.status == OutrightOrderStatus.delivered;

    return BlocListener<OutrightOrdersBloc, OutrightOrdersState>(
      listener: (context, state) {
        if (state.deliveryStatus == DeliveryStatus.success) {
          Navigator.of(context).pop();
          showAppSnackbar("Order Marked as Delivered! ✅", SnackbarType.success);
        } else if (state.deliveryStatus == DeliveryStatus.failure) {
          Navigator.of(context).pop();
          showAppSnackbar(state.errorMessage, SnackbarType.error);
        }
      },
      child: BlocBuilder<OutrightOrdersBloc, OutrightOrdersState>(
        builder: (context, state) {
          final bool isLoading = state.deliveryStatus == DeliveryStatus.loading;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // Title & Status
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Order Details",
                                style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800)),
                            Text("ID: ${o.id.substring(0, 8).toUpperCase()}",
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (o.webPurchase) ...[
                        Container(
                          margin: EdgeInsets.only(right: 6.w),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8FF),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "WEB",
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: const Color(0xFF175CD3)),
                          ),
                        ),
                      ],
                      _StatusPill(status: o.status),
                    ],
                  ),
                ),

                Divider(height: 32.h, color: Colors.grey.shade100),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- AWAITING PAYMENT (web orders, pre-webhook) ---
                        if (awaitingPayment) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.hourglass_top_rounded,
                                    size: 32.sp, color: const Color(0xFFB95000)),
                                SizedBox(height: 12.h),
                                Text("Payment Pending Verification",
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 8.h),
                                Text(
                                  "This web order was placed but the payment has not been confirmed yet. It is not added to your transactions. Once the payment clears, this order becomes actionable automatically.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade600,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],

                        // --- ACTION AREA ---
                        if (isReady || isDelivered) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: isDelivered
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDelivered
                                    ? const Color(0xFF6CE9A6)
                                    : const Color(0xFFFFDDB3),
                                width: 0.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isDelivered
                                      ? Icons.check_circle
                                      : Icons.pending_actions,
                                  size: 32.sp,
                                  color: isDelivered
                                      ? const Color(0xFF027A48)
                                      : const Color(0xFFB95000),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  isDelivered ? "Order Delivered" : "Ready to Deliver",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 8.h),
                                if (isDelivered)
                                  Text(
                                    "Delivered on ${DateFormat('MMM d, h:mm a').format(o.deliveredAt ?? DateTime.now())}",
                                    style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              Analytics.log(
                                                AnalyticsEvents.merchOrderDelivered,
                                                {
                                                  'order_id': o.id,
                                                  'web_purchase': o.webPurchase,
                                                },
                                              );
                                              context.read<OutrightOrdersBloc>().add(OutrightOrderMarkDelivered(o.id));
                                            },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF101828),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))
                                          : Text(
                                              "Mark as Delivered",
                                              style: GoogleFonts.inter(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700
                                              ),
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],

                        // --- CUSTOMER ---
                        Text("CUSTOMER",
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                    o.customerName.isEmpty
                                        ? '?'
                                        : o.customerName[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue)),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o.customerName,
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.sp)),
                                    Text(
                                        o.customerPhone.isNotEmpty
                                            ? o.customerPhone
                                            : "Customer",
                                        style: GoogleFonts.inter(
                                            color: Colors.grey,
                                            fontSize: 12.sp)),
                                    if (o.webPurchase && o.customerEmail.isNotEmpty)
                                      Text(o.customerEmail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                              color: Colors.grey,
                                              fontSize: 12.sp)),
                                  ],
                                ),
                              ),
                              if (o.customerPhone.isNotEmpty)
                                Row(
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.call,
                                      bgColor: Colors.blue.shade50,
                                      iconColor: Colors.blue.shade700,
                                      onTap: () => _launchCall(o.customerPhone),
                                    ),
                                    SizedBox(width: 8.w),
                                    _ActionBtn(
                                      iconWidget: FaIcon(FontAwesomeIcons.whatsapp, size: 18.sp, color: const Color(0xFF25D366)),
                                      bgColor: const Color(0xFFE8FDF0),
                                      iconColor: const Color(0xFF25D366),
                                      onTap: () => _launchWhatsapp(o.customerPhone),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // Delivery address, only when the customer has one on
                        // file. Blank profiles just skip the row — merchant and
                        // customer sort delivery out between themselves.
                        if (o.customerAddress.isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 18.sp, color: Colors.grey.shade500),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    o.customerAddress,
                                    style: GoogleFonts.inter(
                                        fontSize: 12.5.sp,
                                        color: Colors.grey.shade700,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 24.h),

                        // --- ITEMS ORDERED ---
                        Text("ITEMS ORDERED",
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                        SizedBox(height: 12.h),
                        ...o.items.map((item) => _buildOrderItemRow(item)),

                        SizedBox(height: 24.h),

                        // --- SUMMARY ---
                        Text("ORDER SUMMARY",
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                        SizedBox(height: 12.h),
                        _InfoRow(label: "Total Items", value: "${o.items.length}"),
                        SizedBox(height: 8.h),
                        _InfoRow(
                            label: "Total Paid",
                            value: o.totalText,
                            valueColor: Colors.green.shade700,
                            isBold: true),

                        // Campaign tags active when the order was placed —
                        // snapshot copied at purchase, hidden when none.
                        if (o.promotions.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Promotions",
                                  style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade600)),
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
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            child: Text(
                                              tag,
                                              style: GoogleFonts.inter(
                                                  fontSize: 10.5.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFFA54600)),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: 24.h),

                        // --- TIMELINE ---
                        Text("TIMELINE",
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                        SizedBox(height: 12.h),
                        
                        _InfoRow(
                          label: "Ordered On", 
                          value: DateFormat('MMM d, yyyy - h:mm a').format(o.createdAt)
                        ),
                        if (o.deliveredAt != null) ...[
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: "Delivered On", 
                            value: DateFormat('MMM d, yyyy - h:mm a').format(o.deliveredAt!)
                          ),
                        ],
                        if (o.cancelledAt != null) ...[
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: "Cancelled On", 
                            value: DateFormat('MMM d, yyyy - h:mm a').format(o.cancelledAt!),
                            valueColor: const Color(0xFFD92D20)
                          ),
                        ],

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItemRow(OutrightOrderItem item) {
    final priceStr = "₦${(item.unitPrice * item.quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}";
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
                Text(
                  item.displayTitle,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  "Qty: ${item.quantity}  •  ₦${item.unitPrice.toStringAsFixed(0)} each",
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            priceStr,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final OutrightOrderStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case OutrightOrderStatus.awaitingPayment:
        return _buildPill("AWAITING PAYMENT", const Color(0xFFFFF7ED), const Color(0xFFB95000));
      case OutrightOrderStatus.pending:
        return _buildPill("NEW", Colors.blue.shade50, Colors.blue);
      case OutrightOrderStatus.readyToDeliver: 
        return _buildPill("READY TO DELIVER", const Color(0xFFFFF7ED), const Color(0xFFB95000));
      case OutrightOrderStatus.delivered:
        return _buildPill("DELIVERED", const Color(0xFFECFDF3), const Color(0xFF027A48));
      case OutrightOrderStatus.cancelled:
        return _buildPill("CANCELLED", const Color(0xFFFEF3F2), const Color(0xFFB42318));
    }
  }

  Widget _buildPill(String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade600)),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? Colors.black),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onTap;
  final Color bgColor;    
  final Color iconColor; 
  final Widget? iconWidget; 

  const _ActionBtn({
    this.icon, 
    this.iconWidget,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r), 
        decoration: BoxDecoration(
            color: bgColor, 
            shape: BoxShape.circle,
        ),
        child: iconWidget ?? Icon(
          icon, 
          size: 18.sp, 
          color: iconColor, 
        ),
      ),
    );
  }
}
