import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/colors.dart';
import '../../shared/widgets/korra_header.dart';

class MyVendorsScreen extends StatefulWidget {
  final String customerUid;

  const MyVendorsScreen({super.key, required this.customerUid});

  @override
  State<MyVendorsScreen> createState() => _MyVendorsScreenState();
}

class _MyVendorsScreenState extends State<MyVendorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  // Pagination State
  final List<DocumentSnapshot> _vendors = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 15; // Load 15 merchants at a time
  DocumentSnapshot? _lastDocument;

  // Total count for the Top Card
  int _totalMerchantsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTotalCount();
    _loadMoreData();

    // Listen to scroll events to trigger pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 && !_isLoading && _hasMore) {
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🧮 FETCH AGGREGATE TOTAL (For the Top Card)
  Future<void> _fetchTotalCount() async {
    try {
      final query = _firestore
          .collection('customers')
          .doc(widget.customerUid)
          .collection('my_vendors');

      final countQuery = await query.count().get();

      if (mounted) {
        setState(() {
          _totalMerchantsCount = countQuery.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching merchant count: $e");
    }
  }

  // 🔄 PAGINATION LOGIC (List)
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = _firestore
          .collection('customers')
          .doc(widget.customerUid)
          .collection('my_vendors')
          .orderBy('lastInteraction', descending: true) // Most recent first
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _vendors.addAll(snapshot.docs);
        
        if (snapshot.docs.length < _limit) {
          _hasMore = false; // Reached the end
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Pagination Error: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const KorraHeader(title: "My Merchants", showLeadingIcon: true),
      body: Column(
        children: [
          // --- TOP SUMMARY CARD ---
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(24.w),
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  'Merchants Interacted With',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13.sp, fontWeight: FontWeight.w600)
                ),
                SizedBox(height: 8.h),
                Text(
                  '$_totalMerchantsCount',
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 36.sp, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_outlined, color: const Color(0xFFA54600), size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Active Connections',
                        style: GoogleFonts.inter(color: const Color(0xFFA54600), fontWeight: FontWeight.w700, fontSize: 12.sp)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- LIST HEADER ---
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Merchant Directory', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 14.sp)),
              ],
            ),
          ),

          // --- MERCHANT LIST (PAGINATED) ---
          Expanded(
            child: _vendors.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.shop, size: 48.sp, color: Colors.grey.shade300),
                        SizedBox(height: 16.h),
                        Text("No merchants yet", style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade900)),
                        SizedBox(height: 8.h),
                        Text("Merchants you transact with will appear here.", style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.r, 0, 20.r, 20.r),
                    itemCount: _vendors.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      
                      // Show loader at the bottom if fetching more
                      if (index == _vendors.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: KorraColors.brand)),
                        );
                      }

                      final data = _vendors[index].data() as Map<String, dynamic>;
                      final String vendorId = _vendors[index].id;
                      final double credit = (data['storeCredit'] ?? 0).toDouble();

                      return _VendorCard(
                        vendorId: vendorId,
                        storeCredit: credit,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _VendorCard & _SocialBtn REMAIN EXACTLY AS BEFORE
// -----------------------------------------------------------------------------
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
        
        final String name = storeMap['storeName'] ?? 'Unknown Merchant';
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
            border: Border.all(color: Colors.grey.shade200.withOpacity(0.35)),
          ),
          child: Column(
            children: [
              // 1. TOP SECTION: Info & Credit (Clickable to Storefront)
              InkWell(
                onTap: () {
                  final String slug = storeMap['slug'] ?? vendorId;
                  Get.toNamed('/store/$slug');
                },
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                  children: [
                    // Avatar
                    Container(
                      height: 50.h, width: 50.w,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
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
                              Text("Verified Merchant", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
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
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Store Balance", style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xFF166534))),
                            Text(currencyFormat.format(storeCredit), style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                          ],
                        ),
                      )
                  ],
                ),
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
                      iconWidget: Icon(Iconsax.call, size: 20.sp, color: Colors.grey.shade700),
                      label: "Call", 
                      color: Colors.grey.shade700, 
                      onTap: () => _launchUri("tel:$phone"),
                      isVisible: phone.isNotEmpty,
                    ),
                    _SocialBtn(
                      iconWidget: Icon(MdiIcons.whatsapp, size: 20.sp, color: const Color(0xFF25D366)), // WhatsApp
                      label: "WhatsApp", 
                      color: const Color(0xFF25D366), 
                      onTap: () => _launchUri("https://wa.me/${phone.replaceAll('+', '')}"), // Fallback to phone if group link missing
                      isVisible: phone.isNotEmpty,
                    ),
                    _SocialBtn(
                      iconWidget: FaIcon(FontAwesomeIcons.xTwitter, size: 20.sp, color: Colors.black),   // Twitter/X
                      label: "X.com", 
                      color: Colors.black, 
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
  final Widget iconWidget;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isVisible;

  const _SocialBtn({required this.iconWidget, required this.label, required this.color, required this.onTap, required this.isVisible});

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
            iconWidget,
            SizedBox(height: 4.h),
            Text(label, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}