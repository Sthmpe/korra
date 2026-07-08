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

class VendorCampaignsBody extends StatefulWidget {
  final String vendorId;

  const VendorCampaignsBody({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorCampaignsBody> createState() => _VendorCampaignsBodyState();
}

class _VendorCampaignsBodyState extends State<VendorCampaignsBody> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _enterSelection(String campaignId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(campaignId);
    });
  }

  void _toggleSelected(String campaignId) {
    setState(() {
      if (_selectedIds.contains(campaignId)) {
        _selectedIds.remove(campaignId);
      } else {
        _selectedIds.add(campaignId);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _confirmDelete(BuildContext context, List<Campaign> targets) async {
    final plural = targets.length > 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plural ? "Delete ${targets.length} campaigns?" : "Delete this campaign?"),
        content: Text(
          plural
              ? "This ends ${targets.length} campaigns now and reverts any discounted price and tag they applied to their products. This can't be undone."
              : "This ends the campaign now and reverts any discounted price and tag it applied to its products. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<VendorRepository>().deleteCampaigns(targets);
      if (context.mounted) {
        showAppSnackbar(
          plural ? "${targets.length} campaigns deleted." : "Campaign deleted.",
          SnackbarType.success,
        );
        _cancelSelection();
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar("Could not delete campaign(s). Please try again.", SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorId = widget.vendorId;
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

            // 2. Section Header — either the normal title + New Campaign +
            // Select entry point, or the selection toolbar (count + Delete).
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: _selectionMode
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedIds.length} selected',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: KorraColors.textDark,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _cancelSelection,
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              ElevatedButton.icon(
                                onPressed: _selectedIds.isEmpty
                                    ? null
                                    : () => _confirmDelete(
                                          context,
                                          campaigns.where((c) => _selectedIds.contains(c.id)).toList(),
                                        ),
                                icon: Icon(Icons.delete_outline, size: 16.sp),
                                label: Text(
                                  "Delete",
                                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFFB42318),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
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
                          Row(
                            children: [
                              if (campaigns.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(() => _selectionMode = true),
                                  child: Text(
                                    "Select",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFA54600)),
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
                        child: CampaignCard(
                          campaign: campaign,
                          selectionMode: _selectionMode,
                          selected: _selectedIds.contains(campaign.id),
                          onTap: () => _toggleSelected(campaign.id),
                          onLongPress: () => _enterSelection(campaign.id),
                          onDeleteTap: () => _confirmDelete(context, [campaign]),
                        ),
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
      builder: (context) => CreateCampaignSheet(vendorId: widget.vendorId),
    );
  }

  Future<void> _clearMockData(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      final query = await firestore
          .collection('campaigns')
          .where('vendorId', isEqualTo: widget.vendorId)
          .where('isMock', isEqualTo: true)
          .get();

      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      // Reset visibility stats
      final visibilityRef = firestore.collection('vendor_visibility').doc(widget.vendorId);
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
