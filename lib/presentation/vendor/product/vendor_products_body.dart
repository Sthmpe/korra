import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart'; // Premium Icons

import '../../../config/constants/colors.dart';
import '../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';

// We will build these widgets next
import 'widgets/product_list_item_premium.dart';
import 'widgets/product_search_bar.dart';
import 'widgets/product_filter_pills.dart';
import 'widgets/product_details_screen.dart';
import 'widgets/product_edit_screen.dart';

class VendorProductsBody extends StatelessWidget {
  const VendorProductsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorProductsBloc, VendorProductsState>(
      builder: (context, state) {
        // Handle "Init" Loading differently (Shimmer preferred, but spinner for now)
        if (state.items.isEmpty && (state.isSubmitting ?? false)) {
          return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
        }

        return RefreshIndicator(
          color: KorraColors.brand,
          backgroundColor: Colors.white,
          onRefresh: () async => context.read<VendorProductsBloc>().add(const VendorProductsRefresh()),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Search & Filter Header (Sticky-ish feel via SliverToBox)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white, // Continues from AppBar
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: ProductSearchBar(
                          initialValue: state.query,
                          onChanged: (q) => context.read<VendorProductsBloc>().add(VendorProductsQueryChanged(q)),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ProductFilterPills(
                        activeFilter: state.filter,
                        counts: state.statusCounts,
                        onChanged: (f) => context.read<VendorProductsBloc>().add(VendorProductsFilterChanged(f)),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. The List or Empty State
              if (state.visibleItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, state),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = state.visibleItems[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: ProductListItemPremium(
                            product: product,
                            onTap: () => Get.to(() => BlocProvider.value(
                              value: context.read<VendorProductsBloc>(),
                              child: ProductDetailsScreen(product: product),
                            )),
                            onEdit: () => _navigateToEdit(context, product),
                            onShare: product.shareable
                                ? () => context.read<VendorProductsBloc>().add(VendorProductsSharePressed(product))
                                : null,
                          ),
                        );
                      },
                      childCount: state.visibleItems.length,
                    ),
                  ),
                ),
              
              // 3. Bottom Padding for Scroll
              SliverToBoxAdapter(child: SizedBox(height: 40.h)),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEdit(BuildContext context, dynamic product) {
    Get.to(() => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<VendorProductsBloc>()),
        BlocProvider(create: (_) => ImageBloc()),
      ],
      child: ProductEditScreen(product: product),
    ));
  }

  Widget _buildEmptyState(BuildContext context, VendorProductsState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.box_remove, size: 40.sp, color: Colors.grey.shade400),
          ),
          SizedBox(height: 16.h),
          Text(
            "No products found",
            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          SizedBox(height: 8.h),
          Text(
            "Try adjusting your search or filters.",
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}