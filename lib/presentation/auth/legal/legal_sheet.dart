import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// --- PUBLIC FUNCTIONS ---

Future<void> showKorraVendorTermsSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Vendor Terms of Service',
    sections: [
      _Section(
        heading: '1. The Vendor Program',
        items: [
          'Korra operates as a financial infrastructure tool designed to facilitate reservation-based transactions. We act as a payment processor and agreement recorder, not a marketplace or an escrow agent.',
          'You retain full autonomy over your customer sourcing and sales agreements. Korra provides the digital rails to structure payments and secure price locks.',
          'You may choose between two transaction models: "Strict Lock" (for binding reservations) or "Flexi Direct" (for open arrangements).',
        ],
      ),
      _Section(
        heading: '2. Fees & Commission (3.5%)',
        items: [
          'Korra charges a flat Platform Fee of 3.5% on every credit settled to your Vendor Wallet.',
          'This fee serves as consideration for the use of our automated bookkeeping, payment gateway infrastructure, and reservation technology.',
          'The 3.5% fee is automatically deducted "on-entry" when funds are credited to your wallet. The balance reflected in your wallet is fully withdrawable.',
        ],
      ),
      _Section(
        heading: '3. Payments & Settlement Agreement',
        items: [
          'Settlements are processed based on the Agreement Terms, not delivery verification.',
          'For "Strict Lock" Plans: Funds are held for a mandatory 24-hour cooling-off period. After 24 hours, 50% of paid funds are automatically released to your wallet to formalize the reservation.',
          'For "Flexi Direct" Plans: Funds are settled to your wallet immediately after payment.',
          'Price Lock Obligations: Under "Flexi Direct", you must strictly honor the price lock and terms agreed upon initiation. Under "Strict Lock", you are obligated to maintain the reservation as long as the customer is active, and you must respect the customer’s right to extend the duration up to the maximum allowable days.',
          'Refunds: In the event of a customer default or cancellation under the "Strict Lock" agreement, refunds are processed automatically according to the pre-agreed terms (e.g., 50% retention as liquidated damages) without requiring dispute adjudication.',
        ],
      ),
      _Section(
        heading: '4. Delivery & Logistics Responsibility',
        items: [
          'Korra does not oversee logistics, enforce shipping timelines, or require proof of delivery (Waybills). Delivery is a private contractual obligation between you and the Customer.',
          'Funds are released based on the payment schedule and agreement milestones, not on physical handover of goods.',
          'You bear full liability for fulfilling orders. Any failure to deliver after funds are settled constitutes a breach of contract with the Customer, for which you are solely responsible.',
        ],
      ),
      _Section(
        heading: '5. Prohibited Items & Conduct',
        items: [
          'The listing or sale of illegal, counterfeit, stolen, or prohibited items is strictly forbidden. Korra maintains a zero-tolerance policy for illicit trade.',
          'We reserve the right to suspend accounts and freeze funds if activity violates Nigerian law or CBN financial regulations.',
          'Bypassing the platform to complete a Korra-initiated transaction offline to avoid fees is a violation of these terms.',
        ],
      ),
      _Section(
        heading: '6. Liability, Reputation & Transparency',
        items: [
          'You are solely liable for maintaining your business reputation. Korra does not mediate product quality disputes.',
          'You agree to maintain transparency with your customers regarding stock availability and delivery timelines.',
          'In the event of a breach of contract (e.g., failure to deliver after collecting funds), you acknowledge that you are personally liable to the Customer, and Korra may provide your verified identity details to relevant parties for resolution.',
        ],
      ),
      _Section(
        heading: '7. Amendments',
        items: [
          'Korra reserves the right to update these terms. Continued use of the Vendor App constitutes acceptance of the updated terms.',
        ],
      ),
    ],
  );
}

Future<void> showKorraVendorPartnershipSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Partnership & Integrity Policy',
    sections: [
      _Section(
        heading: '1. The Core Relationship',
        items: [
          'Korra Finance acts solely as the payment infrastructure and agreement recording tool. We are not a retailer, distributor, or warehouse.',
          'You (The Vendor) retain full legal title and liability for the quality, authenticity, and physical custody of the products you list.',
          'By accepting ANY deposit (Strict or Direct), you enter a binding legal contract with the Customer to lock the price and reserve the inventory immediately.',
        ],
      ),
      _Section(
        heading: '2. Inventory Integrity (Immediate Price Lock)',
        items: [
          'The "Price Lock" is active from Day 1 (the moment the customer makes the first down payment), regardless of when funds settle to your wallet.',
          'You MUST remove the item from your public shelf immediately upon the first deposit. Selling a reserved item to a walk-in customer or another online buyer constitutes a Breach of Contract.',
          'This obligation applies to both "Strict Lock" and "Flexi Direct" models. The customer is entitled to the locked price as long as they are active on the plan.',
        ],
      ),
      _Section(
        heading: '3. Delivery & Handover Protocol',
        items: [
          'You are responsible for arranging delivery or pickup directly with the Customer.',
          'Korra does not employ riders or manage logistics. Any delay, loss, or damage during transit is a matter between you, the Customer, and the Logistics Provider.',
          'You must not mark an item as "Shipped" or "Delivered" in the app until physical handover has occurred or a valid Waybill has been generated.',
        ],
      ),
      _Section(
        heading: '4. Handling Defaults & Discipline Layers',
        items: [
          'Under "Strict Lock", the system enforces financial discipline:',
          '   - First 24 Hours: Customer can cancel with only a minor processing fee deduction. You receive no funds during this cooling-off period.',
          '   - After 24 Hours: Liquidated Damages activate. If the customer defaults or cancels, you retain 50% of the funds paid so far as compensation for holding inventory.',
          'Under "Flexi Direct", you resolve financial breaches directly with the customer, but you must honor the price lock agreement until a breach is confirmed.',
        ],
      ),
      _Section(
        heading: '5. Product Quality & Liability',
        items: [
          'You guarantee that "What You See Is What You Get". The product must match the exact description and images shared via the link.',
          'The sale of counterfeit (fake), stolen, or refurbished items sold as "New" is strictly prohibited.',
          'If a customer reports a verified defect or fake specification, you are contractually obligated to resolve the matter immediately (whether through replacement, refund, or warranty service). Korra is not liable for your inventory quality.',
        ],
      ),
      _Section(
        heading: '6. Social Media & Identity Transparency',
        items: [
          'You agree to maintain active, verifiable contact details. Korra reserves the right to audit your business reputation.',
          'In the event of a dispute where you become unresponsive (ghosting), Korra is authorized to release your verified Identity Details (BVN Name, Phone, Address) to the Customer to facilitate police action.',
        ],
      ),
      _Section(
        heading: '7. Legal Enforcement',
        items: [
          'This agreement is governed by the laws of the Federal Republic of Nigeria.',
          'Any attempt to defraud the platform or the customer (e.g., collecting deposits without having stock) will be reported to the EFCC and the Nigerian Police Force for prosecution.',
        ],
      ),
    ],
  );
}

Future<void> showKorraVendorPrivacySheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Vendor Privacy Policy',
    sections: [
      _Section(
        heading: '1. Information We Collect',
        items: [
          'Identity Data: NIN, BVN, and Government-issued ID details for KYC compliance.',
          'Business Data: CAC Certificate (if applicable), Store Address, and Bank Account details.',
          'Social Reputation Data: We collect and monitor your provided social media handles (Instagram, TikTok, etc.) to verify business legitimacy and activity.',
          'Transaction Data: History of sales, payouts, refunds, and dispute records.',
        ],
      ),
      _Section(
        heading: '2. How We Use Your Data',
        items: [
          'To verify that your business is real and not a "ghost" shop.',
          'To process wallet settlements and manage the 10-day cooling-off period.',
          'To conduct background checks and fraud risk assessments.',
          'To comply with CBN (Central Bank of Nigeria) and anti-money laundering (AML) regulations.',
        ],
      ),
      _Section(
        heading: '3. Data Sharing',
        items: [
          'We do not sell your data. We only share it with:',
          'Payment Processors: To facilitate transfers to your bank account.',
          'Law Enforcement: We are legally obligated to share your details with the EFCC or Police if there is evidence of inventory fraud or theft.',
        ],
      ),
      _Section(
        heading: '4. Handling of Customer Data',
        items: [
          'Strict Usage: You will receive Customer details (Name, Phone, Address) solely for the purpose of order fulfillment.',
          'No Poaching: You are strictly prohibited from saving Customer data to market to them privately or divert them off the Korra platform.',
          'Data Secrecy: You must not share Customer details with third parties other than your logistics rider.',
        ],
      ),
      _Section(
        heading: '5. Data Security',
        items: [
          'We use bank-grade encryption to protect your personal and financial information.',
          'However, you are responsible for keeping your App Password and Transaction PIN confidential.',
        ],
      ),
      _Section(
        heading: '6. Data Retention',
        items: [
          'We retain your transaction and KYC records for a minimum of 5 years as required by Nigerian financial law, even if you close your account.',
        ],
      ),
      _Section(
        heading: '7. Your Rights & Updates',
        items: [
          'You have the right to request corrections to your business details via Support.',
          'We may update this policy periodically. Continued use of the app signifies acceptance of the changes.',
        ],
      ),
    ],
  );
}

Future<void> showKorraTermsSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Customer Terms of Service',
    sections: [
      _Section(
        heading: '1. About Korra Reservation',
        items: [
          'Korra is a financial reservation tool. We allow you to structure "Reserve & Pay" agreements with Vendors.',
          'We are NOT a marketplace or a retailer. We do not own the goods. We facilitate the payment agreement between you and the Vendor.',
          'You are responsible for verifying the Vendor\'s reputation before transacting. Korra verifies Identity (KYC), not product quality.',
        ],
      ),
      _Section(
        heading: '2. Fees & Charges',
        items: [
          'Korra charges a Platform Fee of 3.5% on plan initiation.',
          'This fee covers payment gateway charges and the cost of securing the "Price Lock" technology.',
          'This fee is non-refundable, even if you cancel the plan.',
        ],
      ),
      _Section(
        heading: '3. "Strict Lock" Rules (24-Hour Cooling Off)',
        items: [
          'If your plan is a "Strict Lock" plan:',
          'You have a 24-hour grace period. You can cancel for a 100% Refund of your deposit (minus the breakage fee).',
          '24 Hours Onwards: 50% of your funds are released to the Vendor to secure full ownership of the item.',
          'Cancellation Penalty: If you cancel AFTER 24 hours, based on the plan terms, you may either forfeit 50% of total funds paid as "Liquidated Damages" or refunds are processed strictly as Store Credit.',
        ],
      ),
      _Section(
        heading: '4. "Flexi Direct" Rules',
        items: [
          'If your plan is a "Flexi Direct" plan:',
          'The Vendor controls the down payment and funds are settled to the Vendor immediately.',
          'Cash refunds are NOT guaranteed. If you cancel a Direct plan, refunds are processed strictly as Store Credit valid only with that specific Vendor.',
        ],
      ),
      _Section(
        heading: '5. Delivery & Logistics',
        items: [
          'Korra does not manage delivery. Delivery is arranged between you and the Vendor.',
          'We strongly recommend using insured courier services (GIG, Kwik, DHL).',
          'If a Vendor fails to deliver after you complete payment, Korra will assist by providing the Vendor\'s Verified Identity Details to help you seek redress.',
        ],
      ),
      _Section(
        heading: '6. Acceptable Use',
        items: [
          'You agree to provide accurate identity details for KYC verification.',
          'You agree to complete payments within the agreed duration. Failure to pay may result in plan termination and loss of deposit.',
        ],
      ),
      _Section(
        heading: '7. Changes to Terms',
        items: [
          'Korra may update these terms. Continued use of the app signifies your acceptance of any changes.',
        ],
      ),
    ],
  );
}

Future<void> showKorraPrivacySheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Privacy Policy',
    sections: [
      _Section(
        heading: '1. Information We Collect',
        items: [
          'To provide our services, we collect personal details (e.g., name, email, phone), verification data (e.g., NIN, BVN), and financial transaction history.',
          'We also collect device metadata and usage logs to detect fraud and secure your account.',
        ],
      ),
      _Section(
        heading: '2. How We Use Your Data',
        items: [
          'Identity Verification: To comply with KYC (Know Your Customer) and AML (Anti-Money Laundering) regulations.',
          'Service Delivery: To process payments, manage reservation plans, and coordinate with vendors.',
          'Security: To monitor for suspicious activity and unauthorized access.',
        ],
      ),
      _Section(
        heading: '3. Information Sharing',
        items: [
          'We do not sell your personal data. Information is shared only with verified third parties essential to our service (e.g., Monnify for payments, vendors for order fulfillment).',
          'We may disclose data to regulatory authorities or law enforcement if legally compelled to do so.',
        ],
      ),
      _Section(
        heading: '4. Data Security',
        items: [
          'We employ industry-standard encryption (bank-grade security) to protect your data both in transit and at rest.',
          'While we implement robust security measures, no digital transmission is absolute. You are responsible for keeping your login credentials confidential.',
        ],
      ),
      _Section(
        heading: '5. Your Rights',
        items: [
          'You have the right to access, correct, or request the deletion of your personal data.',
          'Note that financial transaction records must be retained for a statutory period to comply with financial regulations, even after account closure.',
        ],
      ),
      _Section(
        heading: '6. Updates to Policy',
        items: [
          'We may update this policy to reflect changes in our practices or legal requirements. Significant changes will be communicated directly via the app.',
        ],
      ),
      _Section(
        heading: '7. Contact Us',
        items: [
          'For privacy-related inquiries or to exercise your rights, please contact our Data Compliance team via the Help section.',
        ],
      ),
    ],
  );
}

// --- PRIVATE HELPERS ---

Future<void> _showSheet(
  BuildContext context, {
  required String title,
  required List<_Section> sections,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Handle visuals inside
    builder: (_) => _LegalSheet(title: title, sections: sections),
  );
}

class _LegalSheet extends StatelessWidget {
  final String title;
  final List<_Section> sections;
  const _LegalSheet({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: EdgeInsets.only(top: 40.h), // Prevent hitting very top
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug content or expand
          children: [
            // --- HEADER (Fixed) ---
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 20.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENT (Scrollable) ---
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                itemCount: sections.length,
                separatorBuilder: (_, __) => SizedBox(height: 24.h),
                itemBuilder: (_, i) => sections[i],
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111), // Almost black
          ),
        ),
        SizedBox(height: 8.h),
        ...items.map(
          (t) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Styled Bullet Point
                Container(
                  margin: EdgeInsets.only(top: 7.h, right: 10.w),
                  width: 5.r,
                  height: 5.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9CA3AF), // Muted grey bullet
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      height: 1.5, // Readable line height
                      color: const Color(
                        0xFF4B5563,
                      ), // Grey-600 (Standard reading grey)
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
