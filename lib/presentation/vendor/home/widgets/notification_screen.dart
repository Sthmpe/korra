import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/korra_header.dart';

class NotificationScreen extends StatelessWidget {
  final dynamic repo; // Accepts VendorRepository or CustomerRepository
  final String uid;
  final VoidCallback? onJumpToPlans; // Not heavily used by vendor, can be null

  const NotificationScreen({
    super.key,
    required this.repo,
    required this.uid,
    this.onJumpToPlans,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(title: "Notifications", showLeadingIcon: true),
      body: StreamBuilder<QuerySnapshot>(
        // Assuming your repo has this stream helper, or access firestore directly here
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification, size: 48.sp, color: Colors.grey.shade300),
                  SizedBox(height: 12.h),
                  Text("No notifications yet", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(height: 24.h, color: const Color(0xFFF2F4F7)),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final isRead = data['isRead'] ?? false;
              final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return InkWell(
                onTap: () {
                  // Mark as read when tapped
                  if (!isRead) {
                    FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(uid)
                        .collection('notifications')
                        .doc(id)
                        .update({'isRead': true});
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot for Unread
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: isRead ? Colors.transparent : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'Notification',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: const Color(0xFF101828),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            data['body'] ?? '',
                            style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF667085)),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            DateFormat('MMM d, h:mm a').format(date),
                            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
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
}