import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/widgets/korra_header.dart';

// --- 1. THE DATA MODEL (Separation of Concerns) ---
class LegalDoc {
  final String title;
  final String lastUpdated;
  final String content; // In a real app, this might be Markdown or HTML

  const LegalDoc(this.title, this.lastUpdated, this.content);
}

// --- 2. MOCK DATA (Replace with API fetch later) ---
const _terms = """
1. Introduction
Welcome to Korra. By using our app, you agree to these terms. We facilitate payments and reservations between you and vendors.

2. Reservations & Payments
When you start a plan, you are committing to pay the full amount. Korra is not a bank; we act as a technology provider. Funds are processed by licensed partners (Monnify).

3. Cancellations
You may cancel a plan within 10 days. A breakage fee of 10% of the initial deposit applies to cover reservation costs.

4. Vendor Liability
Korra verifies vendors but is not liable for the quality of goods. All product warranties are provided directly by the vendor.
""";

const _privacy = """
1. Data Collection
We collect your name, email, phone number, and BVN/NIN for identity verification as required by CBN regulations.

2. Data Usage
Your data is used solely to process payments, verify identity, and prevent fraud. We do not sell your data to third parties.

3. Security
We use bank-grade encryption (AES-256) to protect your information. Your card details are tokenized and never stored on our servers.
""";

final List<LegalDoc> _documents = [
  LegalDoc("Terms of Service", "Nov 2025", _terms),
  LegalDoc("Privacy Policy", "Oct 2025", _privacy),
  LegalDoc("Acceptable Use Policy", "Aug 2025", "You agree not to use Korra for illegal activities, money laundering, or purchasing prohibited items."),
];

// --- 3. THE MENU SCREEN ---
class LegalMenuScreen extends StatelessWidget {
  const LegalMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "Legal & Privacy", showLeadingIcon: true),
      body: ListView.separated(
        padding: EdgeInsets.all(20.w),
        itemCount: _documents.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return _LegalMenuTile(
            doc: doc,
            onTap: () => Get.to(() => LegalDetailScreen(doc: doc)),
          );
        },
      ),
    );
  }
}

// --- 4. THE READER SCREEN ---
class LegalDetailScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalDetailScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(
        title: doc.title, 
        showLeadingIcon: true,
        onBackpressed: () => Get.back(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meta Header
            Text(
              "Last updated: ${doc.lastUpdated}",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24.h),
            
            // The Content
            Text(
              doc.content,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                height: 1.6, // Higher line-height for readability
                color: const Color(0xFF344054), // Soft dark grey (easier on eyes than black)
                fontWeight: FontWeight.w400,
              ),
            ),
            
            SizedBox(height: 40.h),
            
            // Footer
            Center(
              child: Icon(Icons.gavel, size: 24.sp, color: Colors.grey.shade300),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. HELPER WIDGETS ---
class _LegalMenuTile extends StatelessWidget {
  final LegalDoc doc;
  final VoidCallback onTap;

  const _LegalMenuTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.document_text, size: 20.sp, color: const Color(0xFF475467)),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF101828)),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Last updated ${doc.lastUpdated}",
                    style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}