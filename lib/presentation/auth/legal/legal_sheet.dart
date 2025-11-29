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
          'Korra is a financial tool that helps you close sales by offering layaway (installment) plans to your customers.',
          'You retain the responsibility for marketing your goods and bringing customers. Korra provides the technology to secure the payment and reservation.',
          'By using Korra, you agree to reserve items securely once a customer commits to a plan.',
        ],
      ),
      _Section(
        heading: '2. Fees & Commission (7.5%)',
        items: [
          'Korra charges a flat platform Service Fee of 7.5% on the total listed price of every item sold through the app.',
          'This fee covers payment processing, float financing, and the technology platform.',
          'The 7.5% fee is automatically deducted from the total amount before it is settled to your Vendor Wallet.',
          'Example: For a ₦100,000 item, Korra deducts ₦7,500. Your final payout is ₦92,500.',
        ],
      ),
      _Section(
        heading: '3. Payments & Settlement',
        items: [
          'To protect against fraud and buyer remorse, Vendor payouts are processed after a 10-days refund window following the customer’s first down payment.',
          'If a customer cancels within this 10-day window, the transaction is voided, and no payout is made.',
          'After the 10-day window settlement will be made to your wallet, the funds are yours. Korra does not reverse settlements unless fraud is detected.',
        ],
      ),
      _Section(
        heading: '4. Delivery & Custody',
        items: [
          'Do NOT release goods until you receive the "Payment Complete" notification from Korra.',
          'You are the custodian of the goods. You must ensure the reserved item is kept safe, clean, and available for immediate pickup once payment is complete.',
          'If an item is found to be damaged or missing when the customer comes to pick it up, you are liable for the full refund.',
        ],
      ),
      _Section(
        heading: '5. Prohibited Conduct',
        items: [
          'Taking Korra customers off the platform to avoid the 7.5% fee is strictly prohibited and will lead to an immediate ban.',
          'Accepting direct cash payments for a Korra order violates our anti-fraud policies.',
          'Listing counterfeit, stolen, or non-existent items is a criminal offense.',
        ],
      ),
      _Section(
        heading: '6. Privacy & Data',
        items: [
          'We collect your KYC details (NIN, BVN, Address) to comply with CBN financial regulations.',
          'In the event of inventory fraud (running away with our float), you authorize Korra to share your details with law enforcement agencies.',
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
          'Korra Finance acts solely as a payment and float provider. We are not a retailer and do not own a warehouse.',
          'You (The Vendor) retain full legal liability for the quality, authenticity, and availability of the products you list on Korra.',
          'By accepting our float payment (or the customer’s down payment), you enter a binding legal contract to reserve the specific inventory for the duration of the plan.',
        ],
      ),
      _Section(
        heading: '2. Inventory Custody (The "No Double-Selling" Rule)',
        items: [
          'Once a payment is made, the specific item ordered is legally "Reserved Inventory" under the constructive possession of Korra.',
          'You MUST remove the item from your public shelf immediately. You are strictly prohibited from selling this item to a walk-in customer or another online buyer.',
          'Selling a reserved item to another party constitutes criminal fraud and will lead to immediate account suspension and police involvement.',
        ],
      ),
      _Section(
        heading: '3. Delivery & Release of Goods',
        items: [
          'STRICT RULE: You must NOT release goods to a customer until you receive an official "Release Authorization" notification from Korra.',
          'Releasing an item without Korra’s consent voids your protection. If the customer has not finished paying, you will be liable for the loss.',
          'Once Korra authorizes the release, the actual delivery arrangement (pickup or logistics) is handled between you and the customer. Korra does not manage the riders.',
        ],
      ),
      _Section(
        heading: '4. Defaulted Orders & Clearance Protocol',
        items: [
          'If a customer fails to complete payment within the agreed timeframe (90-120 days), Korra assumes rights to the item to recover capital.',
          'You agree to act as a fulfillment partner in this scenario. You will hold the item until Korra finds a new buyer via the "Korra Clearance" channel.',
          'When a new buyer is found, you agree to hand over the item to them/their rider. You will receive a Fulfillment Fee for this service.',
          'If you refuse to release the item to the new buyer, you must refund the full original value of the item to Korra within 24 hours.',
        ],
      ),
      _Section(
        heading: '5. Product Quality & Liability',
        items: [
          'You guarantee that "What You See Is What You Get". The product must match the exact description and images listed.',
          'The sale of counterfeit (fake) or refurbished items sold as "New" is strictly prohibited.',
          'If a customer returns an item due to a verified defect or fake specification, you are liable to refund Korra immediately and cover the return shipping costs.',
        ],
      ),
      _Section(
        heading: '6. Social Media & KYC',
        items: [
          'You agree to provide active, verifiable social media handles. Korra reserves the right to audit your business reputation.',
          'Providing false contact information or using a "burner" identity is grounds for permanent blacklisting.',
        ],
      ),
      _Section(
        heading: '7. Legal Enforcement',
        items: [
          'This agreement is governed by the laws of the Federal Republic of Nigeria.',
          'Any attempt to defraud the platform (e.g., running away with float money, selling reserved goods) will be reported to the EFCC and the Nigerian Police Force for prosecution.',
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
    title: 'Terms of Service',
    sections: [
      _Section(
        heading: 'About Korra Reservation',
        items: [
          'Korra allows you to reserve items and pay in installments. We partner with vendors to secure your item while you complete your payment plan.',
          'To activate a reservation, you are required to pay a dynamic down payment. This amount varies based on the item price and vendor settings.',
        ],
      ),
      _Section(
        heading: 'Fees & Charges',
        items: [
          'We do not charge an arbitrary service fee or interest rate on your item price.',
          'The only additional cost is a standard transaction processing fee (charged by our payment partner, Monnify) whenever you fund your wallet or make a payment.',
        ],
      ),
      _Section(
        heading: 'Strict 10-Day Refund Window',
        items: [
          'You have exactly 10 days from the date of your initial down payment to cancel your plan and request a refund.',
          'Refunds processed within this window are subject to a Breaking Fee of 10% of the minimum required down payment for the item (regardless of how much you actually deposited).',
          'The final refund amount will be: Total Amount Paid minus (Breaking Fee + Non-refundable Transaction Charges).',
        ],
      ),
      _Section(
        heading: 'Plan Closure & Default',
        items: [
          'After the 10-day window expires, your reservation is considered "Closed" and final. You are contractually obligated to complete the remaining payments.',
          'Refunds are NOT available after 10 days. If you default on payments after this period, resolutions are not guaranteed and are granted only under exceptional circumstances at Korra’s sole discretion.',
        ],
      ),
      _Section(
        heading: 'Payments & Schedule',
        items: [
          'You are responsible for following the payment schedule you selected.',
          'Items will only be released for delivery once the total amount has been fully paid and confirmed.',
        ],
      ),
      _Section(
        heading: 'Acceptable Use',
        items: [
          'You agree to provide accurate identity details for KYC verification.',
          'Do not use Korra for fraudulent transactions. We reserve the right to suspend accounts suspected of misuse.',
        ],
      ),
      _Section(
        heading: 'Changes to Terms',
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
        heading: 'Information We Collect',
        items: [
          'To provide our services, we collect personal details (e.g., name, email, phone), verification data (e.g., NIN, BVN), and financial transaction history.',
          'We also collect device metadata and usage logs to detect fraud and secure your account.',
        ],
      ),
      _Section(
        heading: 'How We Use Your Data',
        items: [
          'Identity Verification: To comply with KYC (Know Your Customer) and AML (Anti-Money Laundering) regulations.',
          'Service Delivery: To process payments, manage reservation plans, and coordinate with vendors.',
          'Security: To monitor for suspicious activity and unauthorized access.',
        ],
      ),
      _Section(
        heading: 'Information Sharing',
        items: [
          'We do not sell your personal data. Information is shared only with verified third parties essential to our service (e.g., Monnify for payments, vendors for order fulfillment).',
          'We may disclose data to regulatory authorities or law enforcement if legally compelled to do so.',
        ],
      ),
      _Section(
        heading: 'Data Security',
        items: [
          'We employ industry-standard encryption (bank-grade security) to protect your data both in transit and at rest.',
          'While we implement robust security measures, no digital transmission is absolute. You are responsible for keeping your login credentials confidential.',
        ],
      ),
      _Section(
        heading: 'Your Rights',
        items: [
          'You have the right to access, correct, or request the deletion of your personal data.',
          'Note that financial transaction records must be retained for a statutory period to comply with financial regulations, even after account closure.',
        ],
      ),
      _Section(
        heading: 'Updates to Policy',
        items: [
          'We may update this policy to reflect changes in our practices or legal requirements. Significant changes will be communicated directly via the app.',
        ],
      ),
      _Section(
        heading: 'Contact Us',
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
