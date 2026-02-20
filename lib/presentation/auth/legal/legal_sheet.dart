import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// --- PUBLIC FUNCTIONS ---

Future<void> showKorraVendorTermsSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Merchant Terms of Service',
    sections: [
      _Section(
        heading: '1. The Merchant Program',
        items: [
          'Korra operates as a financial infrastructure tool designed to facilitate reservation-based transactions. We act as a payment processor and agreement recorder, not a marketplace or an escrow agent.',
          'You (The Merchant) retain full autonomy over your customer sourcing and sales agreements. Korra provides the digital rails to structure payments and secure inventory reservations.',
          'We connect you with customers who want to "Reserve Now, Pay Later", securing your sales volume in advance.',
        ],
      ),
      _Section(
        heading: '2. Fees & Commission (3.5%)',
        items: [
          'Korra charges a flat Platform Fee of 3.5% on funds settled to your Merchant Wallet.',
          'This fee serves as consideration for the use of our automated bookkeeping, payment gateway infrastructure, and reservation technology.',
          'The 3.5% fee is automatically deducted "on-entry" when funds are credited to your wallet. The remaining balance reflected in your wallet is fully withdrawable.',
        ],
      ),
      _Section(
        heading: '3. Payments & Store Balance Policy',
        items: [
          'Settlements are processed directly to your Merchant Wallet.',
          'No Cash Refunds: Under the Korra agreement, cash refunds are NOT processed for closed plans. If a customer closes a plan, the funds are converted into Store Balance valid specifically with your store.',
          'By using Korra, you agree to honor this Store Balance for future purchases by that customer.',
          'Inventory Obligation: You are obligated to maintain the reservation and the agreed price as long as the customer has an active plan.',
        ],
      ),
      _Section(
        heading: '4. Delivery & Logistics Responsibility',
        items: [
          'Korra does not oversee logistics or enforce shipping timelines. Delivery is a private contractual obligation between you and the Customer.',
          'Funds are released based on the payment schedule, not on the physical handover of goods.',
          'You bear full liability for fulfilling orders. Any failure to deliver after funds are settled constitutes a breach of contract with the Customer, for which you are solely responsible.',
        ],
      ),
      _Section(
        heading: '5. Prohibited Items & Conduct',
        items: [
          'The listing or sale of illegal, counterfeit, stolen, or prohibited items is strictly forbidden. Korra maintains a zero-tolerance policy for illicit trade.',
          'We reserve the right to suspend accounts and freeze funds if activity violates Nigerian law or CBN financial regulations.',
        ],
      ),
      _Section(
        heading: '6. Liability, Reputation & Transparency',
        items: [
          'You are solely liable for maintaining your business reputation. Korra does not mediate product quality disputes.',
          'You guarantee that the product delivered matches the description provided. Issues regarding authenticity, quality, or warranty are your sole responsibility.',
          'In the event of a breach of contract (e.g., failure to deliver after collecting funds), you explicitly authorize Korra to provide your verified identity details (KYC) to the Customer or Law Enforcement to facilitate resolution.',
          'By creating an account or using the Korra App, you legally agree to be bound by these Terms. If you do not agree, you must discontinue use immediately.',
        ],
      ),
      _Section(
        heading: '7. Changes to Terms',
        items: [
          'Korra reserves the right to update these terms. Continued use of the Merchant App constitutes acceptance of the updated terms.',
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
          'Korra acts solely as the payment infrastructure and agreement recording tool. We are not a retailer, distributor, or warehouse.',
          'You (The Merchant) retain full legal title and liability for the quality, authenticity, and physical custody of the products you list.',
          'By accepting an Initial Deposit, you enter a binding legal contract with the Customer to lock the price and reserve the inventory immediately.',
        ],
      ),
      _Section(
        heading: '2. Inventory Integrity (Immediate Price Lock)',
        items: [
          'The "Price Lock" is active from Day 1 (the moment the customer makes the Initial Deposit).',
          'You MUST remove the item from your public shelf immediately upon the first deposit. Selling a reserved item to a walk-in customer or another online buyer constitutes a Breach of Contract.',
        ],
      ),
      _Section(
        heading: '3. Delivery & Handover Protocol',
        items: [
          'You are responsible for arranging delivery or pickup directly with the Customer.',
          'Korra does not employ riders or manage logistics. Any delay, loss, or damage during transit is a matter between you, the Customer, and the Logistics Provider.',
          'You must not mark an item as "Fulfilled" in the app until physical handover has occurred.',
        ],
      ),
      _Section(
        heading: '4. Handling Closed Plans (Store Balance)',
        items: [
          'We enforce a strict "No Cash Refund" policy to protect your cash flow.',
          'If a customer closes a plan, the funds you have already received remain with you. However, you now hold a liability to the customer in the form of Store Balance.',
          'You must allow the customer to use this balance to purchase other items from your store in the future.',
        ],
      ),
      _Section(
        heading: '5. Product Quality & Liability',
        items: [
          'You guarantee that "What You See Is What You Get". The product must match the exact description and images shared via the link.',
          'The sale of counterfeit (fake), stolen, or refurbished items sold as "New" is strictly prohibited.',
          'If a customer reports a verified defect or fake specification, you are contractually obligated to resolve the matter immediately. Korra is not liable for your inventory quality.',
        ],
      ),
      _Section(
        heading: '6. Social Media & Identity Transparency',
        items: [
          'You agree to maintain active, verifiable contact details. Korra reserves the right to audit your business reputation.',
          'In the event of a dispute where you become unresponsive ("ghosting"), Korra is authorized to release your verified Identity Details (BVN Name, Phone, Address) to the Customer to facilitate police action.',
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
    title: 'Merchant Privacy Policy',
    sections: [
      _Section(
        heading: '1. Information We Collect',
        items: [
          'Identity Data: NIN, BVN, and Government-issued ID details for KYC compliance.',
          'Business Data: CAC Certificate (if applicable), Store Address, and Bank Account details.',
          'Social Reputation Data: We collect and monitor your provided social media handles to verify business legitimacy.',
          'Transaction Data: History of sales, payouts, and Store Balance records.',
        ],
      ),
      _Section(
        heading: '2. How We Use Your Data',
        items: [
          'To verify that your business is real and not a "ghost" shop.',
          'To process wallet settlements and manage Store Balance ledgers.',
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
          'Korra is a financial reservation tool. We allow you to structure "Reserve & Pay" agreements with Merchants.',
          'We are NOT a marketplace or a retailer. We do not own the goods. We facilitate the payment agreement between you and the Merchant.',
          'You are responsible for verifying the Merchant\'s reputation before transacting. Korra verifies Identity (KYC), not product quality.',
        ],
      ),
      _Section(
        heading: '2. Fees & Charges',
        items: [
          'Korra charges a Platform Fee of 3.5% on plan initiation.',
          'This fee covers the cost of securing the "Price Lock" technology.',
          'This fee is non-refundable.',
        ],
      ),
      _Section(
        heading: '3. Store Balance Policy',
        items: [
          'By creating a plan, you are reserving an item and removing it from the market. Therefore, Cash Refunds are NOT available.',
          'If you close your plan for any reason, 100% of the principal amount you paid will be converted into Store Balance.',
          'This Store Balance is valid specifically with the Merchant you reserved from and can be used for future purchases.',
          'There are no closing penalties. You keep the full value of what you paid, securely held as balance.',
        ],
      ),
      _Section(
        heading: '4. Merchant Responsibility',
        items: [
          'The Merchant is solely responsible for the authenticity, quality, and warranty of the product.',
          'Korra does not inspect goods. "What You See Is What You Get" depends on the Merchant\'s integrity.',
          'If a Merchant fails to deliver or sells a fake product, you must resolve this directly with them. Korra will assist by providing the Merchant\'s Verified Identity Details to help you seek legal redress.',
        ],
      ),
      _Section(
        heading: '5. Delivery & Logistics',
        items: [
          'Korra does not manage delivery. Delivery is arranged between you and the Merchant.',
          'We strongly recommend using insured courier services.',
          'Ensure you inspect the item immediately upon collection. Releasing the Collection Code signifies your acceptance of the item.',
        ],
      ),
      _Section(
        heading: '6. Acceptance & Prohibited Conduct',
        items: [
          // 1. The Binding Agreement (The Lock)
          'By creating an account or using the Korra App, you legally agree to be bound by these Terms. If you do not agree, you must discontinue use immediately.',
          
          // 2. Anti-Money Laundering (AML) Shield
          'You represent and warrant that all funds used on Korra are from legitimate sources and do not constitute the proceeds of financial crime, fraud, or money laundering.',
          
          // 3. Identity Integrity
          'You agree to provide accurate, current, and verified identity details. Impersonation or the use of false credentials is a criminal offense under Nigerian law.',
          
          // 4. Payment Obligation
          'You agree to complete payments within the agreed duration. Deliberate misuse of the reservation system to manipulate inventory is prohibited.',
        ],
      ),
      
      _Section(
        heading: '7. Governing Law & Jurisdiction',
        items: [
          // 1. The "Home Turf" Rule (Strictly Nigeria)
          'These Terms shall be governed by and construed in accordance with the laws of the Federal Republic of Nigeria.',
          
          // 2. Exclusive Jurisdiction
          'Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts of Nigeria.',
        ],
      ),

      _Section(
        heading: '8. Changes to Terms', // ✅ RESTORED
        items: [
          'Korra reserves the right to update or modify these Terms at any time.',
          'Continued use of the Service following the posting of any changes constitutes acceptance of those changes.',
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
          'Service Delivery: To process payments, manage reservation plans, and coordinate with Merchants.',
          'Security: To monitor for suspicious activity and unauthorized access.',
        ],
      ),
      _Section(
        heading: '3. Information Sharing',
        items: [
          'We do not sell your personal data. Information is shared only with verified third parties essential to our service (e.g., Monnify for payments, Merchants for order fulfillment).',
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