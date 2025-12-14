import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../data/models/customer/korra_notification.dart';
import '../../../../data/repository/customer/customer_repository.dart';
import '../../../../data/repository/customer/notification_repository.dart'; 
import '../../shared/widgets/korra_header.dart';
import '../profile/statements_screen.dart'; 
import '../plans/widgets/empty_state_card.dart';

class NotificationScreen extends StatelessWidget {
  final CustomerRepository repo;
  final String uid;
  final VoidCallback onJumpToPlans; // Function to switch to Plans tab

  const NotificationScreen({
    super.key, 
    required this.repo, 
    required this.uid, 
    required this.onJumpToPlans
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: KorraHeader(
        title: "Notifications", 
        showLeadingIcon: true,
        onBackpressed: () => Get.back(),
        trailingActions: [
          TextButton(
            onPressed: () => repo.markAllRead(uid),
            child: Text(
              "Mark all read", 
              style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFFA54600))
            ),
          )
        ],
      ),
      body: StreamBuilder<List<KorraNotification>>(
        stream: repo.streamNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFA54600)));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: EmptyStateCard(text: "You have no notifications yet."));
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(
                notification: notif,
                onTap: () {
                  // 1. Always Mark as Read on tap
                  if (!notif.isRead) repo.markNotificationRead(uid, notif.id);

                  // 2. Smart Navigation based on Type
                  switch (notif.type) {
                    case 'payment':
                      Get.to(() => StatementsScreen(repo: repo, customerUid: uid));
                      break;
                      
                    case 'reminder':
                    case 'plan':
                      Get.back(); // Close notification screen
                      onJumpToPlans(); // Switch bottom tab to Plans
                      break;
                      
                    case 'security':
                    case 'system':
                      // Usually just informational (Limit update), stays on screen or goes to profile
                      // For now, we just mark read (already done above)
                      break;
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final KorraNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconSpec = _getIconSpec(notification.type);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFF2F4F7), 
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isUnread ? const Color(0xFFEAECF0) : Colors.transparent),
          boxShadow: isUnread ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Bubble
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: iconSpec.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconSpec.icon, size: 20.sp, color: iconSpec.color),
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
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp, 
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: isUnread ? const Color(0xFF101828) : const Color(0xFF667085),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(color: Color(0xFFD92D20), shape: BoxShape.circle))
                      else
                         Icon(Icons.chevron_right_rounded, size: 16.sp, color: Colors.grey.shade400)
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF475467),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _formatTime(notification.createdAt),
                    style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF98A2B3), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat('MMM d').format(dt);
  }

  // --- Visual Specs Helper ---
  _IconSpec _getIconSpec(String type) {
    switch (type) {
      case 'payment': 
        return _IconSpec(Iconsax.wallet_2, const Color(0xFF16A34A), const Color(0xFFDCFCE7)); // Green
      case 'reminder': 
        return _IconSpec(Iconsax.timer_1, const Color(0xFFF79009), const Color(0xFFFEF9C3)); // Orange
      case 'security': 
        return _IconSpec(Iconsax.shield_tick, const Color(0xFFD92D20), const Color(0xFFFEE2E2)); // Red
      case 'system':
        return _IconSpec(Iconsax.trend_up, const Color(0xFF2563EB), const Color(0xFFDBEAFE)); // Blue (For Limit Increase)
      default: 
        return _IconSpec(Iconsax.notification, const Color(0xFFA54600), const Color(0xFFFFEDD5)); // Brand
    }
  }
}

class _IconSpec {
  final IconData icon;
  final Color color;
  final Color bg;
  _IconSpec(this.icon, this.color, this.bg);
}