import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/colors.dart';
import '../../shared/widgets/korra_header.dart';

class MyVendorsScreen extends StatelessWidget {
  final String customerUid;

  const MyVendorsScreen({super.key, required this.customerUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "My Vendors", showLeadingIcon: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .doc(customerUid)
            .collection('my_vendors')
            .orderBy('lastInteraction', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.shop, size: 48.sp, color: Colors.grey.shade300),
                  SizedBox(height: 16.h),
                  Text("No vendors yet", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade900)),
                  SizedBox(height: 8.h),
                  Text("Vendors you transact with will appear here.", style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(20.r),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String vendorId = docs[index].id;
              final double credit = (data['storeCredit'] ?? 0).toDouble();
              
              // We pass the local credit data, but fetch the rest from the Vendor Profile
              return _VendorCard(
                vendorId: vendorId,
                storeCredit: credit,
              );
            },
          );
        },
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final String vendorId;
  final double storeCredit;

  const _VendorCard({required this.vendorId, required this.storeCredit});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('vendors').doc(vendorId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink(); // Loading silently or skeleton

        final vendorData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        // Extract Vendor Details
        final storeMap = vendorData['store'] as Map<String, dynamic>? ?? {};
        final socialsMap = vendorData['socials'] as Map<String, dynamic>? ?? {};
        final personalMap = vendorData['personal'] as Map<String, dynamic>? ?? {};
        
        final String name = storeMap['storeName'] ?? 'Unknown Vendor';
        final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
        final String phone = personalMap['phone'] ?? '';

        // Socials
        final String? whatsapp = socialsMap['whatsappGroup']; // Or direct number
        final String? instagram = socialsMap['instagram'];
        final String? twitter = socialsMap['twitter'];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // 1. TOP SECTION: Info & Credit
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      height: 50.h, width: 50.w,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial, style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                    ),
                    SizedBox(width: 16.w),
                    
                    // Name & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF101828))),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14.sp, color: Colors.blue),
                              SizedBox(width: 4.w),
                              Text("Verified Vendor", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // Store Credit Badge
                    if (storeCredit > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Credit", style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF166534))),
                            Text(currencyFormat.format(storeCredit), style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                          ],
                        ),
                      )
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade100),

              // 2. BOTTOM SECTION: Social Actions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SocialBtn(
                      icon: Iconsax.call, 
                      label: "Call", 
                      color: Colors.grey.shade700, 
                      onTap: () => _launchUri("tel:$phone"),
                      isVisible: phone.isNotEmpty,
                    ),
                    _SocialBtn(
                      icon: Iconsax.message, // WhatsApp
                      label: "WhatsApp", 
                      color: const Color(0xFF25D366), 
                      onTap: () => _launchUri("https://wa.me/${phone.replaceAll('+', '')}"), // Fallback to phone if group link missing
                      isVisible: phone.isNotEmpty,
                    ),
                    _SocialBtn(
                      icon: Iconsax.camera, // Instagram
                      label: "Instagram", 
                      color: const Color(0xFFE1306C), 
                      onTap: () => _launchUri("https://instagram.com/$instagram"), 
                      isVisible: instagram != null && instagram.isNotEmpty,
                    ),
                    _SocialBtn(
                      icon: Iconsax.global, // Twitter/X
                      label: "Twitter", 
                      color: Colors.blue, 
                      onTap: () => _launchUri("https://twitter.com/$twitter"), 
                      isVisible: twitter != null && twitter.isNotEmpty,
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUri(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isVisible;

  const _SocialBtn({required this.icon, required this.label, required this.color, required this.onTap, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          children: [
            Icon(icon, size: 20.sp, color: color),
            SizedBox(height: 4.h),
            Text(label, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}