import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart'; // Premium Icons
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants/colors.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/repository/vendors/vendor_repository.dart';
import '../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../logic/bloc/vendor/product/vendor_products_event.dart';
import '../../../logic/bloc/vendor/product/vendor_products_state.dart';

// We will build these widgets next
import '../../shared/widgets/show_app_snackbar.dart';
import 'widgets/product_grid_item.dart';
import 'widgets/product_list_item_premium.dart';
import 'widgets/product_search_bar.dart';
import 'widgets/product_filter_pills.dart';

class VendorProductsBody extends StatefulWidget {
  final String vendorUid;

  const VendorProductsBody({
    super.key,
    required this.vendorUid,
  });

  @override
  State<VendorProductsBody> createState() => _VendorProductsBodyState();
}

class _VendorProductsBodyState extends State<VendorProductsBody> {
  String get vendorUid => widget.vendorUid;

  // List is the merchant default (management first); the toggle choice
  // sticks across sessions.
  bool _gridView = false;
  static const _gridPrefKey = 'vendor_products_grid_view';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getBool(_gridPrefKey);
      if (saved != null && saved != _gridView && mounted) {
        setState(() => _gridView = saved);
      }
    });
  }

  void _toggleView() {
    setState(() => _gridView = !_gridView);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_gridPrefKey, _gridView));
  }

  @override
  Widget build(BuildContext context) {
    final vendors = context.read<VendorRepository>();
    return BlocConsumer<VendorProductsBloc, VendorProductsState>(
      listenWhen: (previous, current) => current.flow == ProductFlow.delete && previous.success != current.success,
      listener: (context, state) {
        // Handle Success
        if (state.isSubmitting == false) {
          
          if (state.success == true) {
            showAppSnackbar(
              "Product removed and capacity restored.",
              SnackbarType.success,
            );
          } else if (state.errorMessage != null) {
            showAppSnackbar(
              state.errorMessage ?? "Failed to remove product",
              SnackbarType.error,
            );
          }
        }
      },
      builder: (context, state) {
        // Handle "Init" Loading differently (Shimmer preferred, but spinner for now)
        if (state.items.isEmpty && (state.isSubmitting ?? false)) {
          return const Center(child: CircularProgressIndicator(color: KorraColors.brand));
        }

        return RefreshIndicator(
          color: KorraColors.brand,
          backgroundColor: Colors.white,
          onRefresh: () async => context.read<VendorProductsBloc>().add(const VendorProductsRefresh()),
          child: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // 🚀 1. THE NEW LINEAR LOADER (Appears at the very top)
                    if (state.flow == ProductFlow.delete && state.isSubmitting == true)
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              color: const Color(0xFFA54600), // Korra brand color
                              backgroundColor: const Color(0xFFA54600).withOpacity(0.1),
                              minHeight: 3.h,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.h),
                              child: Text(
                                "Deleting product and restoring capacity...",
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              
                    // 2. Search & Filter Header (Your existing code)
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white, // Continues from AppBar
                      padding: EdgeInsets.only(top: 12.h, bottom: 16.h),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ProductSearchBar(
                                    initialValue: state.query,
                                    onChanged: (q) => context.read<VendorProductsBloc>().add(VendorProductsQueryChanged(q)),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // Grid / List toggle (list is the default)
                                IconButton(
                                  onPressed: _toggleView,
                                  icon: Icon(
                                    _gridView
                                        ? Icons.view_agenda_outlined
                                        : Icons.grid_view_rounded,
                                    color: const Color(0xFF1B1B1B),
                                  ),
                                  iconSize: 22.sp,
                                  tooltip: _gridView ? 'List view' : 'Grid view',
                                ),
                              ],
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
              
                  // 3. The List or Empty State
                  if (state.visibleItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context, state),
                    )
                  else if (_gridView)
                    // 2-column catalog grid (opt-in view)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12.h,
                          crossAxisSpacing: 12.w,
                          mainAxisExtent: 226.h,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = state.visibleItems[index];
                            return ProductGridItem(
                              product: product,
                              isSelectionMode: state.isSelectionMode,
                              isSelected: state.selectedIds.contains(product.id),
                              onTap: () {
                                if (state.isSelectionMode) {
                                  context.read<VendorProductsBloc>().add(VendorProductsToggleSelection(product.id));
                                } else {
                                  final currentBloc = context.read<VendorProductsBloc>();
                                  Get.toNamed(
                                    Routes.vendorProductDetails,
                                    arguments: {
                                      'product': product,
                                      'repo': vendors,
                                      'uid': vendorUid,
                                      'listBloc': currentBloc,
                                    },
                                  );
                                }
                              },
                              onLongPress: () => context.read<VendorProductsBloc>().add(VendorProductsToggleSelection(product.id)),
                            );
                          },
                          childCount: state.visibleItems.length,
                        ),
                      ),
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
                                isSelectionMode: state.isSelectionMode,
                                isSelected: state.selectedIds.contains(product.id),
                                onTap: () {
                                  if (state.isSelectionMode) {
                                    context.read<VendorProductsBloc>().add(VendorProductsToggleSelection(product.id));
                                  } else {
                                      // Capture the current bloc
                                      final currentBloc = context.read<VendorProductsBloc>();
                                      
                                      Get.toNamed(
                                        Routes.vendorProductDetails,
                                        arguments: {
                                          'product': product,
                                          'repo': vendors,
                                          'uid': vendorUid,
                                          'listBloc': currentBloc, // 👈 Passing the Bloc
                                        },
                                      );
                                  }
                                },
                                onLongPress: () => context.read<VendorProductsBloc>().add(VendorProductsToggleSelection(product.id)),
                                onEdit: () => _navigateToEdit(context, product),
                                onDelete: () => _showDeleteDialog(context, product),
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
                  
                  // 4. Bottom Padding for Scroll
                  SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                ],
              ),
              
              // 🚀 The Floating Action Bar
               if (state.isSelectionMode)
                  Positioned(
                    bottom: 24.h, left: 20.w, right: 20.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101828), // Dark premium bar
                        borderRadius: BorderRadius.circular(100.r),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Count and close
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white, size: 20.sp),
                                onPressed: () => context.read<VendorProductsBloc>().add(VendorProductsClearSelection()),
                                constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                              ),
                              SizedBox(width: 12.w),
                              Text("${state.selectedIds.length} Selected", 
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp)
                              ),
                            ],
                          ),
                          
                          // Right side: Delete
                          GestureDetector(
                            onTap: () => _showMultiDeleteDialog(context, state.selectedIds.length),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(color: const Color(0xFFD92D20), borderRadius: BorderRadius.circular(100.r)),
                              child: Text("Delete", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.sp)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEdit(BuildContext context, dynamic product) {
    // Capture the current bloc
    final currentBloc = context.read<VendorProductsBloc>();

    Get.toNamed(
      Routes.vendorEditProduct,
      arguments: {
        'product': product,
        'listBloc': currentBloc, // 👈 Passing the Bloc
        'uid': vendorUid,       // 👈 Pass uid to prevent Null type crash
      },
    );
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

  void _showDeleteDialog(BuildContext context, ProductItem product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Product"),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87, height: 1.5),
            children: [
              TextSpan(text: "Are you sure you want to delete "),
              TextSpan(text: "'${product.name}'?\n\n", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                text: "Note: Ongoing plans are still active, but customers won't see this product in your store anymore.",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13.sp),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 1. Fire the bloc event
              context.read<VendorProductsBloc>().add(VendorProductsDelete(product.id));
              // 2. Close the dialog immediately
              Navigator.pop(dialogContext); 
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMultiDeleteDialog(BuildContext context, int selectedCount) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Delete $selectedCount Products"),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87, height: 1.5),
            children: [
              const TextSpan(text: "Are you sure you want to delete these "),
              TextSpan(text: "$selectedCount products?\n\n", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                text: "Note: Ongoing plans are still active, but customers won't see these products in your store anymore.",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13.sp),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 1. Fire the bulk delete event
              context.read<VendorProductsBloc>().add(VendorProductsDeleteMultiple());
              
              // 2. Close the dialog immediately
              Navigator.pop(dialogContext); 
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}