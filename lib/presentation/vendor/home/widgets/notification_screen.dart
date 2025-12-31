import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../shared/widgets/korra_header.dart'; 

class VendorNotificationScreen extends StatelessWidget {
  final String vendorUid;

  const VendorNotificationScreen({
    super.key,
    required this.vendorUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const KorraHeader(title: "Notifications", showLeadingIcon: true),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ Correctly targets 'vendors' collection
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorUid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.notification, size: 40.sp, color: Colors.grey.shade300),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "No notifications yet",
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Order updates and alerts will appear here.",
                    style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(height: 32.h, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? ts = data['createdAt'] as Timestamp?;
              final DateTime date = ts?.toDate() ?? DateTime.now();

              // Icon logic based on type (Optional polish)
              final String type = data['type'] ?? 'system';
              IconData icon;
              Color iconColor;
              Color iconBg;

              if (type == 'vendor_order') {
                icon = Iconsax.box;
                iconColor = Colors.blue.shade700;
                iconBg = Colors.blue.shade50;
              } else if (type == 'payment') {
                icon = Iconsax.wallet_money;
                iconColor = Colors.green.shade700;
                iconBg = Colors.green.shade50;
              } else {
                icon = Iconsax.info_circle;
                iconColor = Colors.grey.shade700;
                iconBg = Colors.grey.shade100;
              }

              return InkWell(
                onTap: () {
                  if (!isRead) {
                    FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(vendorUid)
                        .collection('notifications')
                        .doc(id)
                        .update({'isRead': true});
                  }
                  // TODO: Handle navigation here later if needed (e.g. go to Order Detail)
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(icon, size: 20.sp, color: iconColor),
                    ),
                    SizedBox(width: 14.w),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Notification',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    color: const Color(0xFF101828),
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            data['body'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              height: 1.4,
                              color: const Color(0xFF667085),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _formatDate(date),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}