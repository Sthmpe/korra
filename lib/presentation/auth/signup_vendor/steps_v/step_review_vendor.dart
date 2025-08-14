import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/utils/text_util.dart';

import '../../../../config/constants/sizes.dart';
import '../../../../config/constants/colors.dart';
// import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';
// import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_state.dart';
import '../../legal/legal_sheet.dart';

class StepReviewVendor extends StatelessWidget {
  final GlobalKey<FormState> formKey; // uniform
  const StepReviewVendor({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;

    String presenceLabel() => switch (s.presence) {
      Presence.online => 'Online',
      Presence.physical => 'Physical',
      Presence.both => 'Both',
    };

    Widget row(String k, String v) => Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(width: 120.w, child: Text(k, style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black54))),
          Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w600))),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(16.r),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review & consent', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 12.h),
        
            row('Registered', s.registered ? 'Yes' : 'No'),
            if (s.registered) row('CAC', s.cac),
            if (s.registered) row('Legal name', s.legalName.titleCase),
            row('Store name', s.storeName.titleCase),
            row('Presence', presenceLabel()),
            row('Categories', s.categories.join(', ')),
            if (s.presence != Presence.online) ...[
              row('Address', s.address),
              row('City/State', '${s.city.titleCase}, ${s.stateName.titleCase}'),
            ],
            if (s.mapsLink.isNotEmpty) row('Map', s.mapsLink),
            row('Owner', '${s.ownerFirst.titleCase} ${s.ownerLast.titleCase}  ${s.ownerOther.trim().isEmpty ? '' : ' ${s.ownerOther.titleCase}'}'),
            row('Owner phone', s.ownerPhone),
            row('Email', s.email),
            SizedBox(height: 12.h),
        
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 12.5.sp, color: Colors.black87, height: 1.38),
                children: [
                  const TextSpan(text: 'By creating a vendor account, you agree to Korra’s '),
                  TextSpan(
                    text: 'Terms',
                    style: TextStyle(color: KorraColors.brand, fontWeight: FontWeight.w700),
                    recognizer: TapGestureRecognizer()..onTap = () => showKorraTermsSheet(context),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: KorraColors.brand, fontWeight: FontWeight.w700),
                    recognizer: TapGestureRecognizer()..onTap = () => showKorraPrivacySheet(context),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
