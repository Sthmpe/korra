import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/contacts.dart';

class ContactSupportSheet extends StatelessWidget {
  const ContactSupportSheet({Key? key}) : super(key: key);

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
          // 1. Drag Handle (Standard UI Pattern)
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 24.h),
              width: 48.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // 2. Header Area
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verification Support",
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: const Color(0xFF101828),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Verification usually takes less than 5 minutes. Choose a method below to reach our team.",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF667085),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 32.h),

                // 3. Contact Options (Refined)
                _ContactOption(
                  icon: Icons.chat_bubble_outline,
                  title: "Chat on WhatsApp",
                  subtitle: "Average wait time: 2 min",
                  color: const Color(0xFF25D366),
                  onTap: () => _launchWhatsApp(),
                ),
                SizedBox(height: 16.h),
                _ContactOption(
                  icon: Icons.phone_outlined,
                  title: "Call Support",
                  subtitle: ContactConstants.supportPhone,
                  color: const Color(0xFF007AFF),
                  onTap: () => _launchPhone(),
                ),
                SizedBox(height: 16.h),
                _ContactOption(
                  icon: Icons.email_outlined,
                  title: "Send Email",
                  subtitle: "Response within 24 hours",
                  color: const Color(0xFFF79009),
                  onTap: () => _launchEmail(),
                ),
                SizedBox(height: 48.h), // Bottom padding for safety
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- Launchers ---

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse(
        "https://wa.me/${ContactConstants.whatsappNumber}?text=${Uri.encodeComponent(ContactConstants.whatsappMessage)}"
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  Future<void> _launchPhone() async {
    final url = Uri.parse("tel:${ContactConstants.supportPhone}");
    if (!await launchUrl(url)) {
      debugPrint("Could not launch phone");
    }
  }

  Future<void> _launchEmail() async {
    final url = Uri.parse(
        "mailto:${ContactConstants.supportEmail}?subject=${Uri.encodeComponent(ContactConstants.emailSubject)}"
    );
    if (!await launchUrl(url)) {
      debugPrint("Could not launch email");
    }
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08), // Very subtle background
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF667085),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

