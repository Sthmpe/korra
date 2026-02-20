import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/widgets/korra_header.dart';

class MyStoreCreditsScreen extends StatelessWidget {
  final String customerUid;

  const MyStoreCreditsScreen({super.key, required this.customerUid});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(title: "My Store Balance", showLeadingIcon: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .doc(customerUid)
            .collection('my_vendors')
            .where('storeCredit', isGreaterThan: 0) // ✅ Only show where they have money
            .orderBy('storeCredit', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.wallet_minus, size: 48.sp, color: Colors.grey.shade300),
                  SizedBox(height: 16.h),
                  Text(
                    "No Store Balance Yet",
                    style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Refunds from plans appear here\nas store balance specific to that merchant.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(20.r),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final double credit = (data['storeCredit'] ?? 0).toDouble();
              final String name = data['storeName'] ?? 'Unknown Vendor';
              final Timestamp? lastInteract = data['lastInteraction'];

              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Row(
                  children: [
                    // Vendor Initial
                    Container(
                      height: 48.h, width: 48.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4), // Light Green bg
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "S",
                        style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Available Store Balance",
                            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(credit),
                          style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                        ),
                        if (lastInteract != null)
                          Text(
                            DateFormat('MMM d').format(lastInteract.toDate()),
                            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade400),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}