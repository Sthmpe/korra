import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../shared/widgets/korra_header.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  // --- THE KNOWLEDGE BASE ---
  final List<FaqItem> _allFaqs = [
    FaqItem(
      category: "General",
      question: "How does Korra work?",
      answer: "Korra helps you lock down items you love and pay small-small. \n\n"
              "1. Find a vendor or use their Korra Link.\n"
              "2. Pay the down payment to reserve the item immediately.\n"
              "3. Pay the rest at your own pace (Daily, Weekly, or Monthly).\n"
              "4. Once 100% paid, you pick up your item!"
    ),
    FaqItem(
      category: "Payments & Defaults",
      question: "What happens if I miss a payment?",
      answer: "If you miss a scheduled payment, your plan status changes to 'Overdue'. \n\n"
              "1. You have a grace period to make the payment manually.\n"
              "2. If you remain overdue, your Credit Limit (Reservation Limit) will be reduced.\n"
              "3. Consistent defaults may lead to account suspension."
    ),
    FaqItem(
      category: "Pricing",
      question: "Do I pay extra to use Korra?",
      answer: "No! We do not charge you a reservation fee. \n\n"
              "You only pay the exact price of the product set by the vendor. \n\n"
              "The only extra deduction is the standard Transaction Fee (e.g., bank transfer or gateway charges) which goes directly to the payment processor, not us."
    ),
    FaqItem(
      category: "Plans",
      question: "Why is my plan 'Pending Approval'?",
      answer: "After you pay the down payment, the vendor has to confirm the item is still in stock. \n\n"
              "This usually takes less than 24 hours. If they decline (e.g., out of stock), your money is instantly returned to your wallet."
    ),
    FaqItem(
      category: "Payments",
      question: "What happens if I stop paying?",
      answer: "We understand life happens. If you miss payments, your plan becomes 'Overdue'.\n\n"
              "If you stop paying completely (Default):\n"
              "1. The plan will be cancelled after 90 days.\n"
              "2. You may lose the item reservation.\n"
              "3. A penalty fee will be deducted from your refund."
    ),
    FaqItem(
      category: "Payments & Defaults",
      question: "Can I get a refund if I cancel?",
      answer: "Yes, you can cancel an active plan within the cancellation window. \n\n"
              "However, a 10% Breakage Fee will be deducted from your total deposits to compensate our system. The remaining balance will be refunded to your wallet immediately."
    ),
    FaqItem(
      category: "Payments",
      question: "Why can't I withdraw my wallet balance?",
      answer: "Your Korra Wallet is a 'Reserve Account'. It is designed only for paying vendors. \n\n"
              "If you need to withdraw a refund, please contact support to process a manual transfer back to your bank account."
    ),
    FaqItem(
      category: "Completion",
      question: "I have finished paying. Where is my item?",
      answer: "Congratulations! Once your status shows 'Collection Approved', the item belongs to you.\n\n"
              "Contact the vendor directly using the button on the app to arrange pickup or delivery. Korra does not handle delivery."
    ),
    FaqItem(
      category: "Delivery",
      question: "Who delivers my item?",
      answer: "Delivery is arranged directly between you and the vendor. \n\n"
              "Korra is a payment and reservation tool, not a logistics company. Once your payment is complete, you can:\n"
              "1. Visit the vendor's store to pick up.\n"
              "2. Call the vendor to arrange dispatch (Uber/GIG/Okada).\n"
              "3. Use the contact button on your completion ticket."
    ),
    FaqItem(
      category: "Account",
      question: "How do I increase my Reservation Limit?",
      answer: "Your limit grows automatically! \n\n"
              "1. Complete plans successfully.\n"
              "2. Pay on time (or early).\n"
              "3. Avoid cancellations.\n\n"
              "Our system reviews your history after every completed plan and increases your limit accordingly."
    ),
    FaqItem(
      category: "Account",
      question: "What is my Reservation Limit?",
      answer: "Think of this as your 'Trust Score'. \n\n"
              "It is the maximum product price you can reserve with a standard down payment. \n\n"
              "For example, if your limit is ₦100,000, you can start a plan for any item up to ₦100,000 easily. As you complete plans successfully, this limit increases!"
    ),
    FaqItem(
      category: "Payments",
      question: "What is a 'Gap Payment'?",
      answer: "This helps you buy items bigger than your current Limit! \n\n"
              "If you want an item worth ₦150,000 but your limit is only ₦100,000, the difference (₦50,000) is the Gap. \n\n"
              "To secure the item, you pay the Gap + the standard down payment upfront. This allows you to buy bigger items immediately without waiting for your limit to grow."
    ),
    FaqItem(
      category: "Security",
      question: "Is my bank information safe?",
      answer: "Yes. Korra does not store your card details. All payments and virtual accounts are processed by Monnify, a CBN-licensed payment processor. We use bank-grade encryption to protect your data."
    ),
    FaqItem(
      category: "Trust",
      question: "What if the vendor refuses to give me the item?",
      answer: "This is rare, but we protect you. \n\n"
              "If you have a 'Collection Approved' status, the vendor has been paid and is legally obligated to release the item. Report them immediately via the app, and we will take strict action against their business."
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter Logic
    final filtered = _allFaqs.where((faq) {
      return faq.question.toLowerCase().contains(_query.toLowerCase()) ||
             faq.answer.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "Help Center", showLeadingIcon: true),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search for help (e.g. 'refund')",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
            ),
          ),

          // 2. LIST
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _FaqTile(item: filtered[index]);
              },
            ),
          ),
          
          // 3. SUPPORT CONTACT FOOTER
          Container(
            padding: EdgeInsets.all(20.w),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Still need help?", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                        Text("Our team is available 9am - 5pm", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.sp)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      // Open WhatsApp or Email
                    }, 
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    icon: const Icon(Iconsax.message, size: 18, color: Colors.white),
                    label: Text("Chat Us", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- HELPER CLASSES ---

class FaqItem {
  final String category;
  final String question;
  final String answer;

  FaqItem({required this.category, required this.question, required this.answer});
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            item.question,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF101828),
            ),
          ),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          iconColor: const Color(0xFFA54600), // Brand color
          textColor: const Color(0xFFA54600),
          collapsedIconColor: Colors.grey.shade400,
          children: [
            Text(
              item.answer,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.5, // Better readability
                color: const Color(0xFF475467),
              ),
            ),
          ],
        ),
      ),
    );
  }
}