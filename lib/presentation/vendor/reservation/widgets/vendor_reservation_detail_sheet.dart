import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../../../logic/services/analytics_service.dart';
import '../../../../data/models/vendor/reservation.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_bloc.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_event.dart';
import '../../../../logic/bloc/vendor/reservation/reservations_state.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class VendorReservationDetailSheet extends StatefulWidget {
  final Reservation data;

  const VendorReservationDetailSheet({
    super.key,
    required this.data,
  });

  @override
  State<VendorReservationDetailSheet> createState() =>
      _VendorReservationDetailSheetState();
}

class _VendorReservationDetailSheetState extends State<VendorReservationDetailSheet> {
  
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
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
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
    final d = widget.data;
    final bool isReady = d.isReadyForPickup;
    final bool isFulfilled = d.isFulfilled;

    return BlocListener<ReservationsBloc, ReservationsState>(
      listener: (context, state) {
        if (state.verificationStatus == VerificationStatus.success) {
          Get.back();
          showAppSnackbar("Item Marked as Fulfilled! ✅", SnackbarType.success);
        } else if (state.verificationStatus == VerificationStatus.failure) {
          Get.back();
          showAppSnackbar(state.errorMessage, SnackbarType.error);
        }
      },
      child: BlocBuilder<ReservationsBloc, ReservationsState>(
        builder: (context, state) {
          final bool isLoading = state.verificationStatus == VerificationStatus.loading;

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
                            Text("ID: ${d.id.substring(0, 8)}",
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: Colors.grey)),
                          ],
                        ),
                      ),
                      _StatusPill(status: d.status, isFulfilled: isFulfilled),
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
                        // --- 🚨 ACTION AREA ---
                        if (isReady || isFulfilled) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: isFulfilled
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                  color: isFulfilled
                                      ? const Color(0xFF6CE9A6)
                                      : const Color(0xFFFFDDB3),
                                  width: 0.2,
                                ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isFulfilled
                                      ? Iconsax.verify5
                                      : Iconsax.box_tick,
                                  size: 32.sp,
                                  color: isFulfilled
                                      ? const Color(0xFF027A48)
                                      : const Color(0xFFB95000),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  isFulfilled
                                      ? "Order Delivered"
                                      : "Ready to Deliver",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 8.h),
                                if (isFulfilled)
                                  Text(
                                    "Completed on ${DateFormat('MMM d, h:mm a').format(d.fulfilledAt ?? DateTime.now())}",
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
                                                AnalyticsEvents.merchReservationFulfilled,
                                                {'reservation_id': d.id},
                                              );
                                              // ✅ DIRECT BATCH CALL
                                              context.read<ReservationsBloc>().add(ResMarkFulfilled([d.id]));
                                            },
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF101828),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.r)),
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
                                    d.customerName.isEmpty
                                        ? '?'
                                        : d.customerName[0],
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue)),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.customerName,
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.sp)),
                                    Text("Customer",
                                        style: GoogleFonts.inter(
                                            color: Colors.grey,
                                            fontSize: 12.sp)),
                                  ],
                                ),
                              ),
                              if (d.customerPhone.isNotEmpty && (isReady || isFulfilled))
                                Row(
                                  children: [
                                    _ActionBtn(
                                      icon: Iconsax.call,
                                      bgColor: Colors.blue.shade50,
                                      iconColor: Colors.blue.shade700,
                                      onTap: () => _launchCall(d.customerPhone),
                                    ),
                                    SizedBox(width: 8.w),
                                    _ActionBtn(
                                      iconWidget: FaIcon(FontAwesomeIcons.whatsapp, size: 18.sp, color: const Color(0xFF25D366)),
                                      bgColor: const Color(0xFFE8FDF0),
                                      iconColor: const Color(0xFF25D366),
                                      onTap: () => _launchWhatsapp(d.customerPhone),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // --- FINANCIALS ---
                        Text("FINANCIAL BREAKDOWN",
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.2)),
                        SizedBox(height: 12.h),
                        if (d.variantLabel != null) ...[
                          _InfoRow(
                              label: "Variant",
                              value: d.variantLabel!,
                              isBold: true),
                          SizedBox(height: 8.h),
                        ],
                        _InfoRow(label: "Product Price", value: d.totalText),
                        SizedBox(height: 8.h),
                        _InfoRow(
                            label: "Amount Paid",
                            value: d.paidText,
                            valueColor: Colors.green.shade700,
                            isBold: true),
                        SizedBox(height: 8.h),
                        _InfoRow(
                            label: "Outstanding Balance",
                            value: d.remainingText,
                            valueColor: d.isCompleted
                                ? Colors.grey
                                : const Color(0xFFA54600)),

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
                          label: "Started On", 
                          value: DateFormat('MMM d, yyyy - h:mm a').format(d.createdAt)
                        ),
                        
                        // Show when it was marked "Completed" (fully paid)
                        if (isReady || isFulfilled) ...[
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: "Completed On", 
                            value: DateFormat('MMM d, yyyy - h:mm a').format(d.fulfilledAt ?? d.finalFulfilledAt ?? DateTime.now()), // Use fulfilledAt if available, else fallback to now (shouldn't happen)
                          ),
                        ],
                        
                        if (isFulfilled && d.finalFulfilledAt != null) ...[
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: "Delivered On", 
                            value: DateFormat('MMM d, yyyy - h:mm a').format(d.finalFulfilledAt ?? d.fulfilledAt ?? DateTime.now()),
                          ),
                        ],

                        // ✅ Show when it was cancelled
                        if (d.status == ReservationStatus.cancelled && d.cancelledAt != null) ...[ // Ensure model has cancelledAt
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: "Cancelled On", 
                            value: DateFormat('MMM d, yyyy - h:mm a').format(d.cancelledAt!), // Use cancelledAt if available, else fallback to now (shouldn't happen)
                            valueColor: const Color(0xFFD92D20), // Red text for cancellation
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
}

// Helpers
class _StatusPill extends StatelessWidget {
  final ReservationStatus status;
  final bool isFulfilled;
  const _StatusPill({required this.status, required this.isFulfilled});

  @override
  Widget build(BuildContext context) {
    if (isFulfilled) {
      return _buildPill("DELIVERED", const Color(0xFFECFDF3), const Color(0xFF027A48));
    }

    switch (status) {
      case ReservationStatus.newRes:
        return _buildPill("NEW", Colors.orange.shade50, Colors.orange);
      case ReservationStatus.ongoing:
        return _buildPill("ACTIVE", Colors.blue.shade50, Colors.blue);
      case ReservationStatus.readyForPickup: 
        return _buildPill("READY TO DELIVER", const Color(0xFFFFF7ED), const Color(0xFFB95000));
      case ReservationStatus.completed:
        return _buildPill("DELIVERED", Colors.grey.shade100, Colors.grey.shade700);
      case ReservationStatus.cancelled:
        return _buildPill("CANCELLED", const Color(0xFFFEF3F2), const Color(0xFFB42318));
    }
  }

  Widget _buildPill(String text, Color bg, Color fg) {
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13.sp, color: Colors.grey.shade600)),
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