// lib/presentation/vendor/home/vault_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Direct Firestore Access
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../shared/widgets/korra_header.dart';

class VendorVaultScreen extends StatelessWidget {
  final String vendorUid;

  const VendorVaultScreen({
    super.key,
    required this.vendorUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "Vault Schedule", showLeadingIcon: true),
      body: StreamBuilder<QuerySnapshot>(
        // 1. LISTEN DIRECTLY TO FIRESTORE (Bypasses the Model limitation)
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorUid)
            .collection('ledger_transactions')
            .orderBy('releaseDate', descending: false) // Sort by release date directly
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // 2. FILTER & MAP MANUALLY
          // We manually extract fields since TransactionModel doesn't have them
          final now = DateTime.now();
          
          final lockedFunds = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final releaseTimestamp = data['releaseDate'] as Timestamp?;
            
            // Only show items with a FUTURE release date
            if (releaseTimestamp == null) return false;
            return releaseTimestamp.toDate().isAfter(now);
          }).toList();

          if (lockedFunds.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(20.w),
            itemCount: lockedFunds.length,
            itemBuilder: (context, index) {
              final doc = lockedFunds[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _VaultReleaseTile(
                amount: (data['amount'] ?? 0).toDouble(),
                description: data['description'] ?? 'Locked Funds',
                releaseDate: (data['releaseDate'] as Timestamp).toDate(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.lock_circle, size: 64.sp, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(
            "No funds currently locked",
            style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _VaultReleaseTile extends StatelessWidget {
  final double amount;
  final String description;
  final DateTime releaseDate;

  const _VaultReleaseTile({
    required this.amount,
    required this.description,
    required this.releaseDate,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = releaseDate.difference(DateTime.now()).inDays;
    
    String timeLabel;
    if (daysLeft <= 0) {
      timeLabel = "Releasing Today";
    } else if (daysLeft == 1) {
      timeLabel = "Releasing Tomorrow";
    } else {
      timeLabel = "Releasing in $daysLeft days";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        children: [
          // Lock Icon
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.lock, size: 20.sp, color: const Color(0xFF175CD3)),
          ),
          SizedBox(width: 16.w),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₦${NumberFormat("#,##0.00", "en_US").format(amount.abs())}",
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828)),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Release Date Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  DateFormat('MMM d').format(releaseDate),
                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF344054)),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                timeLabel,
                style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF175CD3), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}