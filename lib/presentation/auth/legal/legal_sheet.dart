import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/constants/korra_legal_links.dart';
import 'legal_pdf_screen.dart';

// --- PUBLIC FUNCTIONS ---

Future<void> showKorraVendorTermsSheet(BuildContext context) async {
  Get.to(
    () => const LegalPdfScreen(
      title: 'Merchant Terms of Service',
      pdfUrl: KorraLinks.vendorTermsPdf,
    ),
    transition: Transition.rightToLeft,
  );
}

Future<void> showKorraVendorPartnershipSheet(BuildContext context) async {
  Get.to(
    () => const LegalPdfScreen(
      title: 'Partnership & Integrity Policy',
      pdfUrl: KorraLinks.vendorPartnershipPdf,
    ),
    transition: Transition.rightToLeft,
  );
}

Future<void> showKorraVendorPrivacySheet(BuildContext context) async {
  Get.to(
    () => const LegalPdfScreen(
      title: 'Merchant Privacy Policy',
      pdfUrl: KorraLinks.vendorPrivacyPdf,
    ),
    transition: Transition.rightToLeft,
  );
}

Future<void> showKorraTermsSheet(BuildContext context) async {
  Get.to(
    () => const LegalPdfScreen(
      title: 'Customer Terms of Service',
      pdfUrl: KorraLinks.customerTermsPdf,
    ),
    transition: Transition.rightToLeft,
  );
}

Future<void> showKorraPrivacySheet(BuildContext context) async {
  Get.to(
    () => const LegalPdfScreen(
      title: 'Privacy Policy',
      pdfUrl: KorraLinks.customerPrivacyPdf,
    ),
    transition: Transition.rightToLeft,
  );
}