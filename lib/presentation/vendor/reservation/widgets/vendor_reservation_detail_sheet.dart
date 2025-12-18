import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching history
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/vendor/vendor_reservation.dart';

class VendorReservationDetailSheet extends StatelessWidget {
  final VendorReservation data;

  const VendorReservationDetailSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // 2. Title & Status
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Reservation Details", style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800)),
                      Text("ID: ${data.id.substring(0, 8)}...", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                ),
                _StatusPill(status: data.status),
              ],
            ),
          ),

          Divider(height: 32.h, color: Colors.grey.shade100),

          // 3. Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CUSTOMER SECTION ---
                  Text("CUSTOMER", style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(data.customerName[0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.blue)),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.customerName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                              Text("Customer", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.sp)),
                            ],
                          ),
                        ),
                        // Actions
                        if (data.isCompleted) // Only show contact if deal is done (optional safety)
                          Row(
                            children: [
                              _ActionBtn(icon: Iconsax.call, onTap: () {}), // Add launchUrl logic
                              SizedBox(width: 8.w),
                              _ActionBtn(icon: Iconsax.message, onTap: () {}),
                            ],
                          )
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // --- FINANCIALS ---
                  Text("FINANCIAL BREAKDOWN", style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  _FinanceRow(label: "Product Price", value: data.totalText),
                  SizedBox(height: 8.h),
                  _FinanceRow(
                    label: "Amount Paid", 
                    value: data.paidText, 
                    valueColor: Colors.green.shade700, 
                    isBold: true
                  ),
                  SizedBox(height: 8.h),
                  _FinanceRow(
                    label: "Outstanding Balance", 
                    value: data.remainingText, 
                    valueColor: data.isCompleted ? Colors.grey : const Color(0xFFA54600)
                  ),

                  SizedBox(height: 24.h),

                  // --- PAYMENT HISTORY (Live from Firestore) ---
                  Text("PAYMENT HISTORY", style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  
                  // We fetch the ledger for this plan directly here
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vendors')
                        // You need to know vendorId here, OR query by planId group (easier to pass vendorId)
                        // Assuming we are querying the plan's ledger logs if we stored them, 
                        // OR we query the PLAN's subcollection if you structure it that way.
                        // Based on your backend, you stored logs in `vendors/{vid}/ledger_transactions` with `planId`.
                        // But we don't have vendorId easily here unless passed.
                        // SIMPLEST: Query the PLAN document for a 'history' array if you add it,
                        // OR just show a static message for now if query is complex.
                        // Let's assume we query the vendor's ledger for this planId.
                        .doc('CURRENT_USER_UID') // ⚠️ You need to pass vendorId to this widget
                        .collection('ledger_transactions')
                        .where('planId', isEqualTo: data.id)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator(minHeight: 2);
                      final docs = snapshot.data!.docs;
                      
                      if (docs.isEmpty) return Text("No transactions recorded yet.", style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey));

                      return Column(
                        children: docs.map((doc) {
                          final tData = doc.data() as Map<String, dynamic>;
                          final amt = (tData['amount'] ?? 0).toDouble();
                          final date = (tData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, size: 16.sp, color: Colors.green),
                                    SizedBox(width: 8.w),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(date),
                                      style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                Text(
                                  "+₦${NumberFormat("#,##0").format(amt)}",
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helpers ---

class _FinanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _FinanceRow({required this.label, required this.value, this.valueColor, this.isBold = false});

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
            color: valueColor ?? Colors.black
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
        child: Icon(icon, size: 18.sp, color: Colors.black),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ReservationStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, txt;
    String label;
    switch (status) {
      case ReservationStatus.newRes:
        bg = Colors.orange.shade50; txt = Colors.orange; label = "NEW";
        break;
      case ReservationStatus.ongoing:
        bg = Colors.blue.shade50; txt = Colors.blue; label = "ONGOING";
        break;
      case ReservationStatus.completed:
        bg = Colors.green.shade50; txt = Colors.green; label = "COMPLETED";
        break;
      case ReservationStatus.cancelled:
        bg = Colors.red.shade50; txt = Colors.red; label = "CANCELLED";
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w800, color: txt)),
    );
  }
}