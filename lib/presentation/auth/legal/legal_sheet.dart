import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/constants/colors.dart';

Future<void> showKorraVendorTermsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (_) => const _LegalSheet(
      title: 'Vendor Terms',
      sections: [
        _Section(
          heading: 'About Korra Vendor Program',
          items: [
            'Korra enables vendors to offer layaway purchases where customers can reserve items and complete payments over time.',
            'Vendors agree to reserve items securely until Korra confirms that full payment is complete or cancellation occurs within the allowed window.',
          ],
        ),
        _Section(
          heading: 'Payments & Settlement',
          items: [
            'Vendor payouts are processed after the 10-day refund window following the customer’s first reservation payment.',
            'If a customer cancels within the 10-day window, no payout is made to the vendor.',
            'Once settlement has been made after the 10-day window, Korra does not reclaim or request refunds from vendors if customers later fail to complete their payments.',
            'All payouts are made directly to the vendor’s registered Korra account details.',
          ],
        ),
        _Section(
          heading: 'Refunds & Cancellation',
          items: [
            'Vendors must not release goods until Korra explicitly notifies them that full payment is completed.',
            'Customers may request a refund only within the initial 10-day window. Vendors must comply with Korra’s refund instructions during this period.',
            'After settlement is made to the vendor, customer defaults or cancellations do not affect vendor payouts.',
          ],
        ),
        _Section(
          heading: 'Vendor Responsibilities',
          items: [
            'Keep reserved items safe, undamaged, and available until delivery is authorized.',
            'Ensure timely delivery once Korra confirms full payment from the customer.',
            'Do not accept direct cash or off-platform payments from customers for Korra layaway purchases.',
            'Vendors may be considered fraudulent if products are tampered with, delivered damaged, or unavailable at the time of confirmed delivery.',
          ],
        ),
        _Section(
          heading: 'Compliance & Fair Use',
          items: [
            'Vendors must provide accurate business, identity, and banking details for KYC verification.',
            'Vendors must not misuse Korra’s platform or engage in fraudulent, deceptive, or misleading practices.',
          ],
        ),
        _Section(
          heading: 'Changes to Vendor Terms',
          items: [
            'Korra may update these Vendor Terms as needed. Continued participation in the Vendor Program means acceptance of the revised Terms.',
          ],
        ),
        _Section(
          heading: 'Contact',
          items: [
            'Need help with your vendor account? Contact Korra Support via the Vendor Help section in the app.',
          ],
        ),
      ],
    ),
  );
}

Future<void> showKorraVendorPrivacySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (_) => const _LegalSheet(
      title: 'Vendor Privacy Policy',
      sections: [
        _Section(
          heading: 'What We Collect',
          items: [
            'Business data (CAC certificate, TIN, bank account information, contact details).',
            'Vendor activity data (transactions, payout history, compliance records).',
          ],
        ),
        _Section(
          heading: 'How We Use It',
          items: [
            'To verify vendor identity and business legitimacy.',
            'To process payouts securely and manage refund windows.',
            'To ensure compliance with regulatory and financial requirements.',
          ],
        ),
        _Section(
          heading: 'Sharing',
          items: [
            'We share vendor information only with payment processors, regulators, and trusted service providers as required.',
            'We may disclose data to regulators or law enforcement when legally required.',
          ],
        ),
        _Section(
          heading: 'Vendor Obligations',
          items: [
            'Keep your business and banking information up to date.',
            'Protect customer goods during the reservation period.',
            'Do not bypass Korra by collecting payments directly from customers.',
          ],
        ),
        _Section(
          heading: 'Security',
          items: [
            'We use strict measures to safeguard vendor data and transactions. No system is 100% secure, but we continuously enhance protection.',
          ],
        ),
        _Section(
          heading: 'Retention',
          items: [
            'We retain vendor information only as long as necessary for regulatory compliance, dispute resolution, and business operations.',
          ],
        ),
        _Section(
          heading: 'Updates',
          items: [
            'We may update this Vendor Privacy Policy. Significant changes will be communicated via the app.',
          ],
        ),
        _Section(
          heading: 'Contact',
          items: [
            'For vendor privacy requests, contact us via the Vendor Help section.',
          ],
        ),
      ],
    ),
  );
}

Future<void> showKorraTermsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (_) => const _LegalSheet(
      title: 'Terms',
      sections: [
        _Section(
          heading: 'About Korra Layaway',
          items: [
            'Korra lets you reserve items and pay in parts. We work with vendors to hold your reservation while you complete payment.',
            'To activate a reservation, you’ll pay an upfront amount (deposit) plus a service charge.',
          ],
        ),
        _Section(
          heading: 'Pricing & Service Charge',
          items: [
            'Each reservation includes a service charge of 15% of the item’s price. This percentage may increase or decrease over time at Korra’s discretion.',
            'Taxes, regulatory fees, or vendor fees may apply depending on your location and the item category.',
          ],
        ),
        _Section(
          heading: 'Payments & Schedule',
          items: [
            'Your reservation is held for you while you complete your scheduled payments.',
            'Missing payments may result in additional reminders, changes to your payment plan, or cancellation in line with vendor policies.',
          ],
        ),
        _Section(
          heading: 'Refunds & Cancellation',
          items: [
            'You have a 10-day window from the date of reservation to request a refund. Within this period, eligible payments (excluding non-refundable fees where applicable) may be returned.',
            'After 10 days, refunds are not guaranteed. Korra may decline, partially approve, or offer an alternative such as extending your payment window at our discretion.',
          ],
        ),
        _Section(
          heading: 'Reservation Assurance',
          items: [
            'We partner with vendors to keep your item reserved while you pay. In the rare event an item becomes unavailable, we’ll work with you on a fair resolution (e.g., refund, replacement, or alternative).',
          ],
        ),
        _Section(
          heading: 'Acceptable Use',
          items: [
            'Provide accurate identity and contact details.',
            'Use Korra for lawful purposes only and respect vendor policies.',
            'Do not misuse promotions, loopholes, or attempt fraud.',
          ],
        ),
        _Section(
          heading: 'Changes to These Terms',
          items: [
            'We may update these Terms from time to time. Continued use of Korra after an update means you accept the revised Terms.',
          ],
        ),
        _Section(
          heading: 'Contact',
          items: ['Questions? Reach out from the Help section in the app.'],
        ),
      ],
    ),
  );
}

Future<void> showKorraPrivacySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (_) => const _LegalSheet(
      title: 'Privacy Policy',
      sections: [
        _Section(
          heading: 'What We Collect',
          items: [
            'Account data (e.g., name, phone, email), identity data (e.g., NIN/BVN), device information, and usage analytics.',
            'Payment and reservation details needed to operate layaway and comply with regulations.',
          ],
        ),
        _Section(
          heading: 'How We Use It',
          items: [
            'To provide and improve Korra services, verify identity, prevent fraud, and meet compliance obligations.',
            'To personalize your experience and communicate important updates.',
          ],
        ),
        _Section(
          heading: 'Sharing',
          items: [
            'We share only what’s necessary with trusted vendors, payment partners, and service providers under strict contractual controls.',
            'We may disclose data when required by law or to protect Korra and our users.',
          ],
        ),
        _Section(
          heading: 'Your Choices',
          items: [
            'You can access, update, or delete certain information from your account.',
            'You may opt out of non-essential marketing communications.',
          ],
        ),
        _Section(
          heading: 'Security',
          items: [
            'We use administrative, technical, and physical safeguards to protect your data. No system is 100% secure, but we work continuously to enhance protection.',
          ],
        ),
        _Section(
          heading: 'Retention',
          items: [
            'We keep information only as long as needed for the purposes described above and to meet legal requirements.',
          ],
        ),
        _Section(
          heading: 'Updates',
          items: [
            'We may update this Privacy Policy. We’ll notify you of significant changes within the app.',
          ],
        ),
        _Section(
          heading: 'Contact',
          items: ['For privacy requests, contact us via the Help section.'],
        ),
      ],
    ),
  );
}

class _LegalSheet extends StatelessWidget {
  final String title;
  final List<_Section> sections;
  const _LegalSheet({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 6.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  itemCount: sections.length,
                  itemBuilder: (_, i) => sections[i],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String heading;
  final List<String> items;
  const _Section({required this.heading, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.inter(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          ...items.map(
            (t) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6.h, right: 8.w),
                    width: 6.r,
                    height: 6.r,
                    decoration: BoxDecoration(
                      color: KorraColors.brand,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        height: 1.42,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
