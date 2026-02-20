import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/data/models/customer/customer_ui_extentsion.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/models/customer/customer_model.dart';
import '../../shared/widgets/korra_header.dart';

class MyQrScreen extends StatelessWidget {
  final Customer customer;

  const MyQrScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // 1. Construct the data string exactly as requested
    // Using firstName is friendlier than full name
    final String qrData = "Hello ${customer.firstName} welcome to korra reserve what you want you get";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Matches profile background
      appBar: const KorraHeader(
        title: 'My QR Code',
        showLeadingIcon: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The QR Code Card
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  //border: Border.all(color: const Color(0xFFEAECF0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // QR Widget from the package
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto, // Automatically determine density
                      size: 220.w,
                      backgroundColor: Colors.white,
                      // Optional: Make the little squares rounder and brand colored
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFFA54600), // Brand color eyes
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: Color(0xFF344054), // Dark grey dots
                      ),
                    ),
                    SizedBox(height: 24.h),
                     Text(
                      customer.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Scan to verify member",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 40.h),
               // Some bottom padding to push it up slightly visually
            ],
          ),
        ),
      ),
    );
  }
}