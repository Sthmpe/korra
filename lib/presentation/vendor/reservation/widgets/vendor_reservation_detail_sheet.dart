import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/colors.dart';
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

class _VendorReservationDetailSheetState
    extends State<VendorReservationDetailSheet> {
  
  // Controller for the hidden input
  final TextEditingController _pinController = TextEditingController();
  
  // State to drive the visual PIN boxes
  String _currentPin = "";

  // ✅ ADDED: Specific launcher for regular phone calls
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

  // ✅ ADDED: Specific launcher for WhatsApp
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

  // ✅ THE MISSING METHOD
  void _processVerification() {
    // 1. Basic Validation
    if (_pinController.text.length != 4) return;

    // 2. Trigger BLoC Event
    // We don't need setState(_isLoading) here because the BLoC state handles loading UI
    context.read<ReservationsBloc>().add(
          ResVerifyPickup(
            planId: widget.data.id,
            pin: _pinController.text,
            customerId: widget.data.customerId ?? '',
          ),
        );
  }

  // ✅ PREMIUM PIN DIALOG (Live Update)
  void _showPinDialog() {
    _pinController.clear();
    // Reset the visual state
    setState(() => _currentPin = ""); 

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionDuration: const Duration(milliseconds: 0),
      transitionBuilder: (ctx, anim1, anim2, child) {
        // Use StatefulBuilder to ensure the dialog rebuilds when typing
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
              backgroundColor: Colors.white,
              elevation: 10,
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF2F4F7)),
                      ),
                      child: const Icon(Iconsax.shield_tick, size: 28, color: KorraColors.brand),
                    ),
                    SizedBox(height: 16.h),
        
                    // Title
                    Text(
                      "Vendor Verification",
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF101828)),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Enter the 4-digit code from the customer's app to release this item.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF667085),
                          height: 1.4),
                    ),
        
                    SizedBox(height: 24.h),
        
                    // ✨ PREMIUM PIN INPUT STACK
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. The Visible Custom Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return _buildPinBox(index, _currentPin);
                          }),
                        ),
        
                        // 2. The Invisible Native TextField
                        Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _pinController,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            onChanged: (val) {
                              // Update the dialog's local state
                              setDialogState(() {
                                _currentPin = val;
                              });
                              // Auto-submit when 4 digits entered
                              if (val.length == 4) {
                                Navigator.pop(ctx);
                                _processVerification();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
        
                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                child: Text("Cancel",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF667085))),
                              ),
                            ),
                      ],
                    ),
        
                    // Actions
                    // Row(
                    //   children: [
                        
                    //     SizedBox(width: 12.w),
                    //     Expanded(
                    //       child: FilledButton(
                    //         onPressed: () {
                    //           Navigator.pop(ctx);
                    //           _processVerification();
                    //         },
                    //         style: FilledButton.styleFrom(
                    //           backgroundColor: const Color(0xFF101828),
                    //           padding: EdgeInsets.symmetric(vertical: 14.h),
                    //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    //           elevation: 0,
                    //         ),
                    //         child: Text("Verify",
                    //             style: GoogleFonts.inter(
                    //                 fontWeight: FontWeight.w700)),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper for the individual Pin Boxes
  // Note: We pass 'currentPin' into it so it renders the correct state
  Widget _buildPinBox(int index, String currentPin) {
    final bool isFilled = currentPin.length > index;
    final bool isFocused = currentPin.length == index;

    final borderColor = isFocused
        ? KorraColors.brand
        : (isFilled ? const Color(0xFFD0D5DD) : const Color(0xFFF2F4F7));

    final bgColor = isFilled ? Colors.white : const Color(0xFFF9FAFB);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 0), // Smooth transition
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      height: 56.w,
      width: 48.w,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1.0),
        boxShadow: isFocused
            ? [
                BoxShadow(
                    color: KorraColors.brand.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0)
              ]
            : [],
      ),
      child: Center(
        child: Text(
          isFilled ? currentPin[index] : "", // Show the number immediately
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF101828),
          ),
        ),
      ),
    );
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
          showAppSnackbar("Handover Verified! Inventory Updated. ✅", SnackbarType.success);;
        } else if (state.verificationStatus == VerificationStatus.failure) {
          Get.back();
          showAppSnackbar(state.errorMessage, SnackbarType.error);
        }
      },
      child: BlocBuilder<ReservationsBloc, ReservationsState>(
        builder: (context, state) {
          final bool isLoading =
              state.verificationStatus == VerificationStatus.loading;

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
                            Text("Reservation Details",
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
                                      ? "Item Handed Over"
                                      : "Ready for Handover",
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 8.h),
                                if (isFulfilled)
                                  Text(
                                    "Collected on ${DateFormat('MMM d, h:mm a').format(d.fulfilledAt!)}",
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
                                          : _showPinDialog,
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
                                              "Verify Pickup PIN",
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
                            // border:
                            //     Border.all(color: const Color(0xFFF3F4F6)),
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
                                    // 1. Call Button (Blue)
                                    _ActionBtn(
                                      icon: Iconsax.call,
                                      bgColor: Colors.blue.shade50,
                                      iconColor: Colors.blue.shade700,
                                      onTap: () => _launchCall(d.customerPhone),
                                    ),
                                    SizedBox(width: 8.w),
                                    // 2. WhatsApp Button (Green)
                                    _ActionBtn(
                                      icon: FontAwesomeIcons.whatsapp,
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
                        _FinanceRow(
                            label: "Product Price", value: d.totalText),
                        SizedBox(height: 8.h),
                        _FinanceRow(
                            label: "Amount Paid",
                            value: d.paidText,
                            valueColor: Colors.green.shade700,
                            isBold: true),
                        SizedBox(height: 8.h),
                        _FinanceRow(
                            label: "Outstanding Balance",
                            value: d.remainingText,
                            valueColor: d.isCompleted
                                ? Colors.grey
                                : const Color(0xFFA54600)),

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
      return _buildPill(
          "FULFILLED", const Color(0xFFECFDF3), const Color(0xFF027A48));
    }

    switch (status) {
      case ReservationStatus.newRes:
        return _buildPill("NEW", Colors.orange.shade50, Colors.orange);
      case ReservationStatus.ongoing:
        return _buildPill("ACTIVE", Colors.blue.shade50, Colors.blue);
      case ReservationStatus.readyForPickup: // ✅ Matches Enum
        return _buildPill("READY TO PICKUP", const Color(0xFFFFF7ED),
            const Color(0xFFB95000));
      case ReservationStatus.completed:
        return _buildPill(
            "COMPLETED", Colors.grey.shade100, Colors.grey.shade700);
      case ReservationStatus.cancelled:
        return _buildPill(
            "CANCELLED", const Color(0xFFFEF3F2), const Color(0xFFB42318));
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

class _FinanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _FinanceRow(
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
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;    
  final Color iconColor; 

  const _ActionBtn({
    required this.icon, 
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r), // Slightly larger tap target
        decoration: BoxDecoration(
            color: bgColor, // Uses the passed color
            shape: BoxShape.circle,
        ),
        child: Icon(
          icon, 
          size: 18.sp, 
          color: iconColor, // Uses the passed color
        ),
      ),
    );
  }
}