import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';

class KycPhoneSection extends StatefulWidget {
  final String phone;
  final bool isEditingPhone;
  final bool isUpdatingPhone;
  final VoidCallback onEditPressed;
  final ValueChanged<String> onSavePressed;

  const KycPhoneSection({
    super.key,
    required this.phone,
    required this.isEditingPhone,
    required this.isUpdatingPhone,
    required this.onEditPressed,
    required this.onSavePressed,
  });

  @override
  State<KycPhoneSection> createState() => _KycPhoneSectionState();
}

class _KycPhoneSectionState extends State<KycPhoneSection> {
  late TextEditingController _phoneCtl;

  @override
  void initState() {
    super.initState();
    _phoneCtl = TextEditingController(text: widget.phone);
  }

  @override
  void didUpdateWidget(KycPhoneSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phone != widget.phone && _phoneCtl.text != widget.phone) {
      _phoneCtl.text = widget.phone;
    }
  }

  @override
  void dispose() {
    _phoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditingPhone) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Iconsax.call, size: 20.sp, color: const Color(0xFF667085)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Registered Phone Number",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.phone.isEmpty ? "No number added" : widget.phone,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF101828),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onEditPressed,
              child: Text(
                "Edit",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: KorraColors.brand,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update Phone Number",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111111),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: KorraColors.brand),
                ),
                child: TextFormField(
                  controller: _phoneCtl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1B1B),
                  ),
                  decoration: InputDecoration(
                    hintText: "080...",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFFAAAAAA),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            widget.onSavePressed(_phoneCtl.text);
          },
          child: Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: KorraColors.brand,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: widget.isUpdatingPhone
                ? SizedBox(
                    height: 20.r,
                    width: 20.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Save",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
