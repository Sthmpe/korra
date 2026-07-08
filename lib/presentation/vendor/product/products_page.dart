import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/constants/colors.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/core/net/net_cubit.dart';
import '../../shared/widgets/korra_header.dart';
import 'vendor_products_body.dart';

import 'widgets/storefront_settings.dart';
import 'widgets/vendor_reviews_body.dart';
import 'widgets/vendor_campaigns_body.dart';

class VendorProductsPage extends StatefulWidget {
  final String vendorUid;
  
  const VendorProductsPage({
    super.key,
    required this.vendorUid,
  });

  @override
  State<VendorProductsPage> createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Reviews stays app-only for now; Campaigns is available on web too, so the
  // tab count/order differs by platform and the header title must follow it.
  List<String> get _tabTitles => [
        'Products',
        'Storefront Settings',
        if (!kIsWeb) 'Ratings & Reviews',
        'Marketing Campaigns',
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update "Add Product" button visibility
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getHeaderTitle() {
    final index = _tabController.index;
    if (index < 0 || index >= _tabTitles.length) return 'Store';
    return _tabTitles[index];
  }

  @override
  Widget build(BuildContext context) {
    final vendorsRepo = context.read<VendorRepository>();
    return BlocProvider(
      create: (_) => VendorProductsBloc(
        vendors: vendorsRepo,
        vendorUid: widget.vendorUid,
        net: context.read<NetCubit>(),
      )..add(const VendorProductsStarted()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: KorraHeader(
              title: _getHeaderTitle(),
              trailingActions: _tabController.index == 0
                  ? [
                      // Minimalist "Add" Button
                      IconButton(
                        onPressed: () async {
                          // 1. Capture the current bloc
                          final currentBloc = context.read<VendorProductsBloc>();

                          // 2. Navigate (Passing the bloc instance)
                          await Get.toNamed(
                            Routes.vendorAddProduct,
                            arguments: {
                              'uid': widget.vendorUid,
                              'listBloc': currentBloc,
                            },
                          );

                          // 3. Trigger Refresh when back
                          if (context.mounted) {
                            currentBloc.add(const VendorProductsRefresh());
                          }
                        },
                        icon: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4ED), // Light orange bg
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.add, 
                            color: const Color(0xFFA54600), 
                            size: 24.sp
                          ),
                        ),
                      ),
                    ]
                  : null,
            ),
            body: Column(
              children: [
                // Top Custom Switch TabBar
                TabBar(
                  controller: _tabController,
                  tabs: [
                    const Tab(text: "Products"),
                    const Tab(text: "Storefront"),
                    if (!kIsWeb) const Tab(text: "Reviews"),
                    const Tab(text: "Campaigns"),
                  ],
                  labelColor: const Color(0xFFA54600),
                  unselectedLabelColor: KorraColors.textMuted,
                  indicatorColor: const Color(0xFFA54600),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.sp),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      VendorProductsBody(
                        vendorUid: widget.vendorUid,
                      ),
                      VendorStorefrontSettings(
                        vendorUid: widget.vendorUid,
                      ),
                      if (!kIsWeb)
                        VendorReviewsBody(
                          vendorId: widget.vendorUid,
                        ),
                      VendorCampaignsBody(
                        vendorId: widget.vendorUid,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}