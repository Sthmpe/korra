import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';

import '../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';

import '../../shared/widgets/section_header.dart';
import 'widgets/product_details_screen.dart';
import 'widgets/product_edit_screen.dart';
import 'widgets/product_search_field.dart';
import 'widgets/product_filters.dart';
import 'widgets/product_list_item.dart';
import 'widgets/product_empty_state.dart';

class VendorProductsBody extends StatelessWidget {
  const VendorProductsBody({super.key});

  String _emptyMessageForFilter(ProductFilter filter, int totalCount) {
    switch (filter) {
      case ProductFilter.approved:
        return "No approved products yet.";
      case ProductFilter.pending:
        return "No pending products awaiting review.";
      case ProductFilter.rejected:
        return "No rejected products.";
      case ProductFilter.outOfStock:
        if (totalCount == 0) {
          return "You haven’t added any products yet.";
        } else {
          return "All your products are in stock.";
        }
      case ProductFilter.all:
      return "You haven’t added any products yet.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorProductsBloc, VendorProductsState>(
      builder: (context, s) {
        return RefreshIndicator(
          onRefresh: () async => context.read<VendorProductsBloc>().add(
            const VendorProductsRefresh(),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.h),
                    ProductSearchField(
                      initial: s.query,
                      onChanged: (q) => context.read<VendorProductsBloc>().add(
                        VendorProductsQueryChanged(q),
                      ),
                      onClear: () => context.read<VendorProductsBloc>().add(
                        const VendorProductsQueryChanged(''),
                      ),
                    ),

                    SizedBox(height: 10.h),
                    ProductFilters(
                      active: s.filter,
                      onChanged: (f) => context.read<VendorProductsBloc>().add(
                        VendorProductsFilterChanged(f),
                      ),
                    ),

                    SectionHeader(
                      title: 'Your products',
                      actionText: s.totalCountLabel,
                    ),

                    if (s.visibleItems.isEmpty)
                      ProductEmptyState(
                        message: _emptyMessageForFilter(s.filter, s.items.length),
                      )
                    else
                      ...s.visibleItems
                          .map(
                            (p) => ProductListItem(
                              p: p,
                              onTap: () => Get.to(() => BlocProvider.value(
                                value: context.read<VendorProductsBloc>(),
                                child: ProductDetailsScreen(product: p),
                              )),
                              onShare:
                                  p.status == ProductStatus.approved &&
                                      p.stock > 0
                                  ? () => context
                                        .read<VendorProductsBloc>()
                                        .add(VendorProductsSharePressed(p))
                                  : null,
                              onEdit: () => Get.to(() => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(
                                    value: context.read<VendorProductsBloc>(),
                                  ),
                                  BlocProvider<ImageBloc>(
                                    create: (_) => ImageBloc(),
                                  ),
                                ],
                                child: ProductEditScreen(product: p),
                              )),
                              onRestock: () => context
                                  .read<VendorProductsBloc>()
                                  .add(VendorProductsRestockPressed(p.id)),
                            ),
                          )
                          .toList(),
                    SizedBox(height: 16.h),
                    if (!(s.isSubmitting ?? false) && s.items.isNotEmpty &&
                        s.visibleItems.length < s.items.length && s.visibleItems.length < s.statusCounts[s.filter]!)
                      Center(
                        child: TextButton(
                          onPressed: () => context
                              .read<VendorProductsBloc>()
                              .add(VendorProductsLoadMore()),
                          child: Text(
                            "Load More",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: KorraColors.brand,
                            ),
                          ),
                        ),
                      ),
                    if ((s.isSubmitting!))
                      Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
