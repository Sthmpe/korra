import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_bloc.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import '../../../../presentation/vendor/product/widgets/share_link_sheet.dart';
import '../../../shared/widgets/korra_header.dart';
import 'product_details_gallery.dart';
import 'product_details_timeline.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductItem product;
  final String vendorUid;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.vendorUid,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool canEdit = product.status != ProductStatus.pending;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: KorraHeader(
        title: "Product Details",
        showLeadingIcon: true,
        trailingActions: [
          if (canEdit)
            IconButton(
              onPressed: () => _navigateToEdit(context),
              icon: Icon(Icons.edit, size: 22.sp, color: const Color(0xFF101828)),
              tooltip: "Edit Product",
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. STATUS BANNER
            if (product.status == ProductStatus.rejected) ...[
              _buildAlertBanner(
                "This product was rejected.", 
                Icons.cancel, 
                const Color(0xFFFEF3F2), 
                const Color(0xFFB42318)
              ),
              SizedBox(height: 20.h),
            ],

            // 2. IMAGE GALLERY
            ProductDetailsGallery(images: product.imageUrl),
            
            SizedBox(height: 24.h),

            // 3. TITLE & PRICE (Fixed Formatting)
            Text(
              product.name,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
                height: 1.3,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  product.priceText,
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: KorraColors.brand, 
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                _StatusPill(status: product.status),
              ],
            ),

            SizedBox(height: 24.h),

            // 4. ACTION BUTTON
            if (product.shareable) ...[
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton.icon(
                  onPressed: () => ShareLinkSheet.show(context, product),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share, size: 20, color: Color(0xFF344054)),
                  label: Text(
                    "Share Link",
                    style: GoogleFonts.inter(
                      fontSize: 15.sp, 
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF344054)
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],

            ProductDetailsTimeline(product: product),

            // 7. STANDARD INFO GRID
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFF2F4F7), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(label: "Stock", value: product.stock.toString()),
                  Container(width: 1, height: 24.h, color: const Color(0xFFEAECF0)),
                  _InfoItem(label: "Category", value: product.category),
                  Container(width: 1, height: 24.h, color: const Color(0xFFEAECF0)),
                  _InfoItem(label: "Added", value: DateFormat('d MMM').format(product.createdAt)),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 8. DESCRIPTION
            Text(
              "Description",
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              product.description,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                color: const Color(0xFF475467),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }




  Widget _buildAlertBanner(String msg, IconData icon, Color bg, Color text) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: text),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(msg, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: text)),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    // 1. Capture the current Bloc instance
    final vendorBloc = context.read<VendorProductsBloc>();

    // 2. Navigate using Named Route (passing the bloc)
    Get.toNamed(
      Routes.vendorEditProduct,
      arguments: {
        'product': widget.product, // Pass the product data
        'listBloc': vendorBloc,    // 👈 Pass the LIVE bloc instance
        'uid': widget.vendorUid,   // Pass the vendor UID for context
      },
    );
  }
}

// ... _InfoItem and _StatusPill widgets (Same as before) ...
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF667085), fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF101828), fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProductStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case ProductStatus.approved:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF027A48);
        label = "Active";
        break;
      case ProductStatus.pending:
        bg = const Color(0xFFFFFAEB);
        text = const Color(0xFFB54708);
        label = "In Review";
        break;
      case ProductStatus.rejected:
        bg = const Color(0xFFFEF3F2);
        text = const Color(0xFFB42318);
        label = "Rejected";
        break;
      case ProductStatus.outOfStock:
        bg = const Color(0xFFF2F4F7);
        text = const Color(0xFF344054);
        label = "Sold Out";
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: bg == const Color(0xFFF2F4F7) ? const Color(0xFFEAECF0) : Colors.transparent),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}