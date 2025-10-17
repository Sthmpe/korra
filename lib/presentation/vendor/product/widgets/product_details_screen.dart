import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:korra/config/constants/colors.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/utils/currency_formatters.dart';
import '../../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../shared/widgets/korra_header.dart';
import 'product_edit_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductItem product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.imageUrl;
    debugPrint('Product images: $images');

    return Scaffold(
      backgroundColor: KorraColors.bg,
      appBar: KorraHeader(
        title: 'Product Details',
        showLeadingIcon: true,
        trailingActions: [
          if (widget.product.status != ProductStatus.pending &&
              widget.product.status != ProductStatus.outOfStock)
            IconButton(
              icon: Icon(
                MdiIcons.storeEdit,
                size: 24.sp,
                color: KorraColors.brand,
              ),
              onPressed: () =>
                  Get.to(() => MultiBlocProvider(
                        providers: [
                          // Pass the existing bloc instance
                          BlocProvider.value(
                            value: context.read<VendorProductsBloc>(),
                          ),

                          // Create a new bloc instance
                          BlocProvider(create: (_) => ImageBloc()),
                        ],
                    child: ProductEditScreen(product: widget.product)
                  )),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- IMAGE CAROUSEL ----------
            images.isNotEmpty
                ? Stack(
                    children: [
                      CarouselSlider.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index, realIdx) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                        options: CarouselOptions(
                          height: 280.h,
                          viewportFraction: 0.95,
                          enableInfiniteScroll: images.length > 1,
                          autoPlay: images.length > 1,
                          autoPlayInterval: const Duration(seconds: 4),
                          onPageChanged: (index, reason) {
                            setState(() => _currentIndex = index);
                          },
                        ),
                      ),
                      // // Gradient overlay (for polish)
                      // Positioned(
                      //   bottom: 0,
                      //   left: 0,
                      //   right: 0,
                      //   child: Container(
                      //     height: 60.h,
                      //     decoration: BoxDecoration(
                      //       gradient: LinearGradient(
                      //         begin: Alignment.bottomCenter,
                      //         end: Alignment.topCenter,
                      //         colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  )
                : Container(
                    height: 280.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 80.sp,
                      color: Colors.grey[600],
                    ),
                  ),
            SizedBox(height: 10.h),

            // ---------- INDICATOR ----------
            if (images.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: isActive ? 18.w : 7.w,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: isActive ? KorraColors.brand : Colors.grey[400],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  );
                }),
              ),

            SizedBox(height: 20.h),

            // ---------- NAME ----------
            Text(
              widget.product.name,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 8.h),

            // ---------- PRICE + STATUS ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatPrice(widget.product.priceText),
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: KorraColors.brand,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(widget.product.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    widget.product.status.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(widget.product.status),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // ---------- DESCRIPTION ----------
            Text(
              "Description",
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              widget.product.description,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            SizedBox(height: 20.h),

            // ---------- INFO BOX ----------
            Divider(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoTile("Stock", widget.product.stock.toString()),
                _infoTile("Category", widget.product.category),
                _infoTile(
                  "Date Added",
                  widget.product.createdAt.toString().split(' ').first,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _statusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.approved:
        return Colors.green;
      case ProductStatus.pending:
        return Colors.orange;
      case ProductStatus.rejected:
        return Colors.redAccent;
      case ProductStatus.outOfStock:
        return Colors.grey;
    }
  }
}
