import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/data/repository/customer/notification_repository.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/customer/korra_notification.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../config/routes/app_routes.dart';
import '../../shared/widgets/korra_header.dart';

class NotificationScreen extends StatelessWidget {
  final CustomerRepository repo;
  final String uid;
  final VoidCallback onJumpToPlans;

  const NotificationScreen({
    super.key,
    required this.repo,
    required this.uid,
    required this.onJumpToPlans,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Matched Vendor: White Background
      appBar: KorraHeader(
        title: "Notifications",
        showLeadingIcon: true,
        onBackpressed: () => Get.back(),
        // Optional: Keep "Mark all read" if you want functionality, 
        // but removed to match Vendor UI strictness. Uncomment if needed.
        
        trailingActions: [
          TextButton(
            onPressed: () => repo.markAllRead(uid),
            child: Text("Mark all read", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: KorraColors.brand)),
          )
        ],
      ),
      body: StreamBuilder<List<KorraNotification>>(
        stream: repo.streamNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
          }

          final notifications = snapshot.data ?? [];

          // ✅ Matched Vendor: Empty State UI
          if (notifications.isEmpty) {
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

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            itemCount: notifications.length,
            // ✅ Matched Vendor: Dividers instead of Spacing
            separatorBuilder: (_, __) => Divider(height: 32.h, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              
              // ✅ Logic to determine Icon Style (Matched Vendor Styling)
              IconData icon;
              Color iconColor;
              Color iconBg;

              switch (notif.type) {
                case 'payment':
                  icon = Iconsax.wallet_money;
                  iconColor = Colors.green.shade700;
                  iconBg = Colors.green.shade50;
                  break;
                case 'plan':
                case 'reminder':
                  icon = Iconsax.box; // Using box for plans like Vendor uses for orders
                  iconColor = Colors.blue.shade700;
                  iconBg = Colors.blue.shade50;
                  break;
                case 'security':
                  icon = Iconsax.shield_tick;
                  iconColor = Colors.red.shade700;
                  iconBg = Colors.red.shade50;
                  break;
                default:
                  icon = Iconsax.info_circle;
                  iconColor = Colors.grey.shade700;
                  iconBg = Colors.grey.shade100;
              }

              return InkWell(
                onTap: () {
                  // 1. Mark Read
                  if (!notif.isRead) repo.markNotificationRead(uid, notif.id);

                  // 2. Navigation Logic (Kept from Customer App)
                  switch (notif.type) {
                    case 'payment':
                      Get.toNamed(
                        Routes.customerStatements, 
                        arguments: {'repo': repo, 'uid': uid}
                      );
                      break;
                    case 'reminder':
                    case 'plan':
                      onJumpToPlans();
                      break;
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Matched Vendor: Icon Box
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
                                  notif.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    // ✅ Matched Vendor: Bolder font for Unread
                                    fontWeight: !notif.isRead ? FontWeight.w800 : FontWeight.w600,
                                    color: const Color(0xFF101828),
                                  ),
                                ),
                              ),
                              // ✅ Matched Vendor: Red Dot for Unread
                              if (!notif.isRead)
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
                            notif.body,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              height: 1.4,
                              color: const Color(0xFF667085),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _formatDate(notif.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
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

  // ✅ Matched Vendor: Date Logic
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