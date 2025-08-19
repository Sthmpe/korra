import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';

import '../../shared/widgets/section_header.dart';
import 'widgets/product_search_field.dart';
import 'widgets/product_filters.dart';
import 'widgets/product_list_item.dart';
import 'widgets/product_empty_state.dart';
import 'widgets/product_create_button.dart';

class VendorProductsBody extends StatelessWidget {
  const VendorProductsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorProductsBloc, VendorProductsState>(
      builder: (context, s) {
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<VendorProductsBloc>().add(const VendorProductsRefresh()),
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
                      onChanged: (q) => context
                          .read<VendorProductsBloc>()
                          .add(VendorProductsQueryChanged(q)),
                      onClear: () => context
                          .read<VendorProductsBloc>()
                          .add(const VendorProductsQueryChanged('')),
                    ),

                    SizedBox(height: 10.h),
                    ProductFilters(
                      active: s.filter,
                      onChanged: (f) => context
                          .read<VendorProductsBloc>()
                          .add(VendorProductsFilterChanged(f)),
                    ),

                    SectionHeader(title: 'Your products', actionText: s.totalCountLabel),

                    if (s.visibleItems.isEmpty)
                      const ProductEmptyState()
                    else
                      ...s.visibleItems
                          .map((p) => ProductListItem(
                                p: p,
                                onShare: p.status == ProductStatus.approved && p.stock > 0
                                    ? () => context
                                        .read<VendorProductsBloc>()
                                        .add(VendorProductsSharePressed(p.id))
                                    : null,
                                onEdit: () => context
                                    .read<VendorProductsBloc>()
                                    .add(VendorProductsEditPressed(p.id)),
                                onRestock: () => context
                                    .read<VendorProductsBloc>()
                                    .add(VendorProductsRestockPressed(p.id)),
                              ))
                          .toList(),

                    SizedBox(height: 16.h),
                    ProductCreateButton(
                      onTap: () => context
                          .read<VendorProductsBloc>()
                          .add(const VendorProductsCreatePressed()),
                    ),
                    SizedBox(height: 28.h),
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
