import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:korra/config/utils/text_util.dart'; 

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
import '../../legal/legal_sheet.dart';

class StepReviewVendor extends StatelessWidget {
  final GlobalKey<FormState> formKey; 
  const StepReviewVendor({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    // 1. Watch the state so the widget rebuilds when 'agreedToTerms' changes
    final s = context.watch<SignupVendorBloc>().state;
    
    // Use the value from the Bloc, not local state
    final isAgreed = s.toggled; 

    String _fullName() {
      final fn = s.firstName.titleCase;
      final ln = s.lastName.titleCase;
      final on = s.otherName.trim().isEmpty ? '' : ' ${s.otherName.titleCase}';
      return '$fn $ln$on';
    }

    String presenceLabel() => switch (s.presence) {
      Presence.online => 'Online Only',
      Presence.physical => 'Physical Store',
      Presence.both => 'Hybrid (Online + Physical)',
    };

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Application',
            style: GoogleFonts.inter(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please confirm your business details before submission.',
            style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
          ),
          SizedBox(height: 32.h),

          // --- BUSINESS SUMMARY CARD ---
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE5E5E5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _SectionHeader(title: "Business Info", icon: Iconsax.shop),
                SizedBox(height: 16.h),
                _ReviewRow(label: "Store Name", value: s.storeName.titleCase),
                _ReviewRow(label: "Registration", value: s.registered ? "Registered (CAC)" : "Unregistered"),
                if (s.registered) ...[
                  _ReviewRow(label: "CAC Number", value: s.cac),
                  _ReviewRow(label: "Legal Name", value: s.legalName.titleCase),
                ],
                _ReviewRow(label: "Categories", value: s.categories.join(', ')),
                
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),

                _SectionHeader(title: "Social Presence", icon: Iconsax.global),
                SizedBox(height: 16.h),
                if (s.instagram.isEmpty && s.twitter.isEmpty && s.facebook.isEmpty && s.tiktok.isEmpty)
                  Text("No social links provided", style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey, fontStyle: FontStyle.italic))
                else ...[
                  if (s.instagram.isNotEmpty) _ReviewRow(label: "Instagram", value: "@${s.instagram}"),
                  if (s.twitter.isNotEmpty) _ReviewRow(label: "Twitter", value: "@${s.twitter}"),
                  // Add other social checks here if needed
                ],

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),

                _SectionHeader(title: "Location", icon: Iconsax.map),
                SizedBox(height: 16.h),
                _ReviewRow(label: "Presence", value: presenceLabel()),
                if (s.presence != Presence.online) ...[
                  _ReviewRow(label: "Address", value: s.address),
                  _ReviewRow(label: "City / State", value: '${s.city.titleCase}, ${s.stateName.titleCase}'),
                ],

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),

                _SectionHeader(title: "Owner", icon: Iconsax.user),
                SizedBox(height: 16.h),
                _ReviewRow(label: "Full Name", value: _fullName()),
                _ReviewRow(label: "Phone", value: s.phone),
                _ReviewRow(label: "Email", value: s.email),
              ],
            ),
          ),
          
          SizedBox(height: 32.h),

          // --- LEGAL CHECKBOX ---
          GestureDetector(
            onTap: () {
              // 2. Dispatch event to Bloc instead of setState
              // Toggle the current value
              context.read<SignupVendorBloc>().add(TermsAgreementToggled(!isAgreed)); 
            },
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                // 3. UI now reacts to 'isAgreed' from Bloc
                color: isAgreed ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB), 
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isAgreed ? const Color(0xFFBBF7D0) : const Color(0xFFF3F4F6)
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: isAgreed ? KorraColors.brand : Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: isAgreed ? KorraColors.brand : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: isAgreed 
                        ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF4B5563),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'By checking this box, I agree to Korra’s '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(color: KorraColors.brand, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => showKorraVendorTermsSheet(context),
                          ),
                          const TextSpan(text: ', '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(color: KorraColors.brand, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => showKorraVendorPrivacySheet(context),
                          ),
                          const TextSpan(text: ', and '),
                          TextSpan(
                            text: 'Vendor Partnership Agreement',
                            style: const TextStyle(color: KorraColors.brand, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => showKorraVendorPartnershipSheet(context),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

// --- COMPONENTS (Unchanged) ---
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: KorraColors.brand),
        SizedBox(width: 8.w),
        Text(title, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF111111))),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: const Color(0xFF8E8E93))),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp, 
                fontWeight: FontWeight.w600, 
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}