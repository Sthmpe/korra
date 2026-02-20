import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart'; 

import '../../../config/constants/contacts.dart';
import '../../shared/widgets/korra_header.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  // --- KNOWLEDGE BASE (Updated for Store Balance & Merchant Terms) ---
  final List<FaqItem> _allFaqs = [
    FaqItem(
      question: "How does Korra work?",
      answer: "Korra allows you to 'Reserve Now, Pay Later' directly with Merchants.\n\n"
              "1. Locate a Merchant and get their reservation link.\n"
              "2. Paste the link in the app to view the item.\n"
              "3. Pay the initial deposit to lock the price and reserve stock immediately.\n"
              "4. Fund the balance at your own pace.\n"
              "5. Pick up your item once fully paid."
    ),
    FaqItem(
      question: "What happens if I close a plan?",
      answer: "We have a strict 'No Cash Refund' policy to protect Merchant inventory.\n\n"
              "If you close a plan, 100% of the principal amount you have paid is instantly converted into Store Balance. You can use this balance to buy other items from the same Merchant in the future."
    ),
    FaqItem(
      question: "Is there a closing penalty?",
      answer: "No. There are no penalties for changing your mind. You retain the full value of your payments, but they are held as Store Balance rather than returned as cash."
    ),
    FaqItem(
      question: "Do I pay extra to use Korra?",
      answer: "We charge a one-time Platform Fee of 3.5% when you start a plan. This fee is non-refundable."
    ),
    FaqItem(
      question: "What if the Merchant sells me a fake product?",
      answer: "The Merchant is solely liable for product quality and authenticity. Korra acts as the payment processor.\n\n"
              "If a Merchant fails to deliver or sells a counterfeit item, please report them. We will provide their verified Identity Details (KYC) to assist you in seeking legal redress."
    ),
    FaqItem(
      question: "Why is my plan 'Pending Approval'?",
      answer: "The Merchant has 24 hours to confirm they have the stock available. If they decline or fail to accept within this window, your money is returned to your wallet instantly."
    ),
    FaqItem(
      question: "Who delivers my item?",
      answer: "Korra does not handle logistics. Delivery or pickup is arranged privately between you and the Merchant. Do not release the 'Collection Code' until you have physically received your item."
    ),
    FaqItem(
      question: "What is 'Store Balance'?",
      answer: "Store Balance is a digital balance held with a specific Merchant. It cannot be withdrawn to your bank, but it can be used as cash to start new plans or buy items from that specific Merchant shop."
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
          // 1. SLEEK SEARCH BAR
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Search questions...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13.sp),
                prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey.shade400, size: 18.sp),
                filled: true,
                fillColor: const Color(0xFFF9FAFB), // Subtle grey
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.5)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                isDense: true, 
              ),
            ),
          ),

          // 2. LIST
          Expanded(
            child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _FaqTile(item: filtered[index]);
                  },
                ),
          ),
          
          // 3. FOOTER
          _buildContactFooter(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.search_status, size: 40.sp, color: Colors.grey.shade300),
          SizedBox(height: 8.h),
          Text(
            "No results found",
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFooter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFF2F4F7))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Still need help?", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                  SizedBox(height: 2.h),
                  Text("support@korra.com.ng", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.sp)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                 final url = Uri.parse(
                    "mailto:${ContactConstants.supportEmail}?subject=${Uri.encodeComponent(ContactConstants.emailSubject)}"
                );
                if (!await launchUrl(url)) {
                  debugPrint("Could not launch email");
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.sms, size: 16.sp, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      "Email Us", 
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, 
                        color: Colors.white,
                        fontSize: 12.sp
                      )
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- HELPER CLASSES ---

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r), 
        border: Border.all(color: const Color(0xFFF2F4F7)), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          
          // Title Styling
          title: Text(
            item.question,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF101828),
            ),
          ),
          
          // Icon Styling
          iconColor: const Color(0xFF101828), 
          collapsedIconColor: const Color(0xFF98A2B3),
          
          // Content
          children: [
            Text(
              item.answer,
              style: GoogleFonts.inter(
                fontSize: 12.sp, 
                height: 1.5,
                color: const Color(0xFF667085), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}