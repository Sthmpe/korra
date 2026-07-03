// lib/presentation/vendor/product/widgets/vendor_campaigns_body.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../data/models/vendor/campaign_model.dart';
import '../../../../data/models/vendor/vendor_visibility.dart';
import '../../../../data/repository/vendors/vendor_repository.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

import 'campaigns/campaign_reach_cards.dart';
import 'campaigns/highlighted_store_promo.dart';
import 'campaigns/campaign_card.dart';
import 'campaigns/create_campaign_sheet.dart';

class VendorCampaignsBody extends StatelessWidget {
  final String vendorId;

  const VendorCampaignsBody({
    super.key,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.read<VendorRepository>();

    return StreamBuilder<List<Campaign>>(
      stream: repository.streamCampaigns(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFA54600),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load campaigns.',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          );
        }

        final campaigns = snapshot.data ?? [];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Analytics & Highlight Store Promo Cards (Scoped Stream to avoid List reloading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: StreamBuilder<VendorVisibility>(
                  stream: repository.streamVisibility(vendorId),
                  builder: (context, visibilitySnapshot) {
                    final visibility = visibilitySnapshot.data ?? VendorVisibility(vendorId: vendorId);
                    return Column(
                      children: [
                        CampaignReachCards(visibility: visibility),
                        SizedBox(height: 12.h),
                        HighlightedStorePromo(vendorId: vendorId, visibility: visibility),
                      ],
                    );
                  },
                ),
              ),
            ),

            // 2. Section Header & Launch Campaign Action
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sent Campaigns (${campaigns.length})',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: KorraColors.textDark,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateCampaignForm(context),
                      icon: Icon(Icons.add, size: 16.sp),
                      label: Text(
                        "New Campaign",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: const Color(0xFFA54600),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Seeder Warning Banner
            if (campaigns.any((c) => c.isMock))
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFFFF4ED),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFFA54600),
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Demo mode active with mock campaigns & orders.",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFA54600),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _clearMockData(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Clear Demo Data",
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFFA54600),
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Feed Body List
            if (campaigns.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final campaign = campaigns[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: CampaignCard(campaign: campaign),
                      );
                    },
                    childCount: campaigns.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 48.sp,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No campaigns yet',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: KorraColors.textDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Launch a marketing campaign to notify your customer network and drive sales.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _seedMockData(context),
              icon: Icon(Icons.playlist_add_rounded, size: 18.sp),
              label: Text(
                "Seed Demo Campaigns",
                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const Color(0xFFA54600),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateCampaignForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r)),
      ),
      builder: (context) => CreateCampaignSheet(vendorId: vendorId),
    );
  }

  Future<void> _seedMockData(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final productTitles = [
      "Premium Wireless Earbuds",
      "Protective Silicone Case",
      "Fast Charging USB-C Adapter",
      "Tempered Glass Screen Protector",
      "Magnetic Car Phone Mount",
      "Leather Card Holder Wallet",
      "Portable Power Bank 10k mAh"
    ];

    final tags = ['New Arrival', 'Flash Sale', 'Best Price', 'Limited Stock', 'Weekend Special'];

    final campaignTitles = [
      "🔥 Flash Sale!",
      "✨ Just Arrived",
      "💰 Big Discount",
      "🛍️ New Stock",
      "🌟 Weekend Deal",
      "⚡ Almost Gone"
    ];

    final captions = [
      "Get up to 30% off our best products today!",
      "Premium items restocked and ready for you.",
      "Fast checkout with easy reservation online.",
      "High quality inventory available right now.",
      "Check out today's flash sale for deals.",
      "Limited stock left, buy yours today!"
    ];

    // 1. Seed 12 Mock Campaigns
    final campaignsRef = firestore.collection('campaigns');
    for (int i = 0; i < 12; i++) {
      final tag = tags[i % tags.length];
      final title = campaignTitles[i % campaignTitles.length];
      final caption = captions[i % captions.length];
      final prodTitle = productTitles[i % productTitles.length];

      final DateTime sentAt = i < 2 
          ? DateTime.now().subtract(Duration(hours: i * 4))
          : DateTime.now().subtract(Duration(hours: i * 12 + 25));

      final doc = campaignsRef.doc();
      batch.set(doc, {
        'vendorId': vendorId,
        'productIds': ['mock_prod_${i % 7}'],
        'productTitles': [prodTitle],
        'tag': tag,
        'title': title,
        'caption': caption,
        'imageUrl': 'https://picsum.photos/400/200?random=$i',
        'sentAt': Timestamp.fromDate(sentAt),
        'openCount': (i * 3) + 2,
        'isMock': true,
        'discountType': i % 3 == 0 ? 'percentage' : 'none',
        'discountValue': i % 3 == 0 ? 20.0 : 0.0,
      });
    }

    // 2. Set mock analytics in vendor_visibility doc
    final visibilityRef = firestore.collection('vendor_visibility').doc(vendorId);
    batch.set(visibilityRef, {
      'topSellerCircles': 214,
      'mostVisitedCircles': 48,
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      if (context.mounted) {
        showAppSnackbar("Successfully seeded mock campaigns and visibility reach stats!", SnackbarType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar("Failed to seed mock campaigns: $e", SnackbarType.error);
      }
    }
  }

  Future<void> _clearMockData(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      final query = await firestore
          .collection('campaigns')
          .where('vendorId', isEqualTo: vendorId)
          .where('isMock', isEqualTo: true)
          .get();

      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      // Reset visibility stats
      final visibilityRef = firestore.collection('vendor_visibility').doc(vendorId);
      batch.set(visibilityRef, {
        'topSellerCircles': 0,
        'mostVisitedCircles': 0,
      }, SetOptions(merge: true));

      await batch.commit();
      if (context.mounted) {
        showAppSnackbar("Mock campaigns and reach stats cleared successfully!", SnackbarType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar("Failed to clear mock campaigns: $e", SnackbarType.error);
      }
    }
  }
}
