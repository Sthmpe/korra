import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../auth/legal/legal_sheet.dart';
import '../../../shared/widgets/korra_header.dart';

// Import your sheet functions here (or keep them in this file for now)
// import 'legal_sheets.dart'; 

// --- 1. DATA MODEL (Action-based) ---
class LegalItem {
  final String title;
  final String lastUpdated;
  final VoidCallback onTap; // Triggers the specific sheet

  LegalItem({
    required this.title, 
    required this.lastUpdated, 
    required this.onTap
  });
}

// --- 2. THE MENU SCREEN ---
class LegalMenuScreen extends StatelessWidget {
  const LegalMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the list of available documents here
    final List<LegalItem> documents = [
      LegalItem(
        title: "Vendor Terms of Service",
        lastUpdated: "Dec 2025",
        onTap: () => showKorraVendorTermsSheet(context), // Defined in previous steps
      ),
      LegalItem(
        title: "Partnership & Integrity Policy",
        lastUpdated: "Nov 2025",
        onTap: () => showKorraVendorPartnershipSheet(context), // Defined in previous steps
      ),
      LegalItem(
        title: "Privacy Policy",
        lastUpdated: "Oct 2025",
        onTap: () => showKorraPrivacySheet(context), // Defined in previous steps
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "Legal & Privacy", showLeadingIcon: true),
      body: ListView.separated(
        padding: EdgeInsets.all(20.w),
        itemCount: documents.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          return _LegalMenuTile(item: documents[index]);
        },
      ),
    );
  }
}

// --- 3. THE TILE WIDGET ---
class _LegalMenuTile extends StatelessWidget {
  final LegalItem item;

  const _LegalMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // Icon Box
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.document_text, 
                  size: 20.sp, 
                  color: const Color(0xFF475467), // Cool Grey
                ),
              ),
              SizedBox(width: 16.w),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp, 
                        fontWeight: FontWeight.w600, 
                        color: const Color(0xFF101828)
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Last updated ${item.lastUpdated}",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp, 
                        color: const Color(0xFF98A2B3)
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right, 
                size: 20.sp, 
                color: const Color(0xFF98A2B3)
              ),
            ],
          ),
        ),
      ),
    );
  }
}