import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
// import 'package:url_launcher/url_launcher.dart'; 

import '../../shared/widgets/korra_header.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  // --- KNOWLEDGE BASE ---
  final List<FaqItem> _allFaqs = [
    FaqItem(
      question: "How does Korra work?",
      answer: "Korra helps you lock down items you love and pay small-small.\n\n"
              "1. Find a vendor or use their Link.\n"
              "2. Pay the down payment to reserve immediately.\n"
              "3. Pay the rest at your own pace.\n"
              "4. Pick up your item once fully paid."
    ),
    FaqItem(
      question: "Can I get a refund if I cancel?",
      answer: "• Within 24 Hours: Yes, full refund (minus 3.5% fee).\n"
              "• After 24 Hours: 50% penalty applies for 'Strict Lock' plans. 'Flexi Direct' refunds are Store Credit only."
    ),
    FaqItem(
      question: "What happens if I miss a payment?",
      answer: "Your plan becomes 'Overdue'. You have a grace period to pay. Consistent defaults may freeze your Active Slots."
    ),
    FaqItem(
      question: "Do I pay extra to use Korra?",
      answer: "We charge a small 3.5% Platform Fee. This covers the payment gateway and Price Lock technology."
    ),
    FaqItem(
      question: "Why is my plan 'Pending Approval'?",
      answer: "The vendor has 24 hours to confirm stock. If they decline or expire, your money returns to your wallet instantly."
    ),
    FaqItem(
      question: "Who delivers my item?",
      answer: "Delivery is arranged between you and the vendor directly. Korra is a payment tool, not a logistics company."
    ),
    FaqItem(
      question: "What is the 'Slot System'?",
      answer: "Slots control how many plans you can run at once. Prove you are reliable to unlock more slots!"
    ),
    FaqItem(
      question: "What if the vendor refuses to deliver?",
      answer: "Report them immediately. If your status is 'Collection Approved', they are legally obligated to release the item."
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter Logic (Search Only)
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
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                isDense: true, // Makes it smaller/compact
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
              onTap: () {
                // Email Launch Logic
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
      margin: EdgeInsets.only(bottom: 8.h), // Tighter spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r), // Smaller radius
        border: Border.all(color: const Color(0xFFF2F4F7)), // Subtle border
        // Very subtle shadow for "premium" feel
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        // Remove default dividers
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          
          // Title Styling
          title: Text(
            item.question,
            style: GoogleFonts.inter(
              fontSize: 13.sp, // Premium small font
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
                fontSize: 12.sp, // Smaller body text
                height: 1.5,
                color: const Color(0xFF667085), // Soft grey
              ),
            ),
          ],
        ),
      ),
    );
  }
}