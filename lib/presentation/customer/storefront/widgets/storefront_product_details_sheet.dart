// lib/presentation/customer/storefront/widgets/storefront_product_details_sheet.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/vendor/campaign_model.dart';
import '../../../../logic/services/analytics_service.dart';
import '../../../../logic/services/recent_views_service.dart';
import '../../store/widgets/deal_countdown_badge.dart';
import 'cart_service.dart';
import 'storefront_details_carousel.dart';
import 'storefront_variant_picker.dart';

/// Premium product details bottom sheet: swipable lazy carousel, price block
/// with discount treatment, availability chips, quantity stepper and the
/// Add to Cart / Pay Installments action pair.
class StorefrontProductDetailsSheet extends StatefulWidget {
  final Product product;
  final DocumentSnapshot? rawDoc;
  final ScrollController scrollController;
  /// (product, quantity, variantLabel) — variantLabel is null for products
  /// without variants; called once per variant line on multi-variant adds.
  final Function(Product, int, String?)? onAddToCart;

  /// (rawDoc, variantLabel) — variantLabel is null for products without
  /// variants; for variant products the customer picks one first (a plan
  /// reserves exactly one unit).
  final Function(DocumentSnapshot?, String?)? onPayInstallments;

  /// Read-only mode (opened from the cart): shows the product info but hides
  /// the quantity stepper and the Add to Cart / Pay Installments actions, and
  /// skips view-recording — peeking at an item already in the cart is not
  /// browsing, so it must not feed Last Viewed or re-engagement.
  final bool readOnly;

  /// The store's running/upcoming timed campaign for this product, if any.
  final Campaign? deal;

  /// The store's slug, used to build the shareable product deep link
  /// (https://korra.com.ng/store/{slug}/p/{productId}). Null hides Share.
  final String? storeSlug;

  const StorefrontProductDetailsSheet({
    super.key,
    required this.product,
    this.rawDoc,
    required this.scrollController,
    this.onAddToCart,
    this.onPayInstallments,
    this.deal,
    this.storeSlug,
    this.readOnly = false,
  });

  @override
  State<StorefrontProductDetailsSheet> createState() => _StorefrontProductDetailsSheetState();
}

class _StorefrontProductDetailsSheetState extends State<StorefrontProductDetailsSheet> {
  int _selectedQuantity = 1;

  /// Selected quantity per variant label (variant products only).
  final Map<String, int> _variantQty = {};

  /// Dwell timing for the Last Viewed feature: a view only counts when the
  /// sheet stayed open for 5+ seconds (see RecentViewsService.minDwell).
  final Stopwatch _dwell = Stopwatch();

  @override
  void initState() {
    super.initState();
    _dwell.start();
  }

  @override
  void dispose() {
    _dwell.stop();
    if (!widget.readOnly) {
      RecentViewsService.instance.recordView(
        widget.product,
        _dwell.elapsed,
        storeSlug: widget.storeSlug,
      );
      Analytics.log(AnalyticsEvents.custProductViewed, {
        'vendor_id': widget.product.vendorId,
        'product_id': widget.product.id,
        'dwell_seconds': _dwell.elapsed.inSeconds,
      });
    }
    super.dispose();
  }

  /// Units of this product the cart already holds — reopening the sheet must
  /// not allow claiming the same stock twice.
  int get _inCart => CartService.instance
      .quantityInCart(widget.product.vendorId, widget.product.id);

  /// Units still addable right now.
  int get _maxAdd =>
      (widget.product.availableStock - _inCart).clamp(0, widget.product.availableStock);

  /// Wraps the carousel-through-availability-banner region so it can be
  /// captured as an image on share (see [_shareProduct]).
  final GlobalKey _shareCaptureKey = GlobalKey();

  Future<void> _shareProduct() async {
    final slug = widget.storeSlug;
    if (slug == null) return;
    Analytics.log(AnalyticsEvents.custProductShared, {
      'vendor_id': widget.product.vendorId,
      'product_id': widget.product.id,
    });
    final url = "https://korra.com.ng/store/$slug/p/${widget.product.id}";
    final caption = "${widget.product.name} on Korra\n$url";

    // Best effort: embed a screenshot of the product card (image through the
    // installment-availability banner) alongside the link. Falls back to a
    // plain text share if capture fails for any reason.
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _shareCaptureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("capture target not ready");

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imageFile = await File('${directory.path}/korra_${widget.product.id}.png').create();
      await imageFile.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(imageFile.path)], text: caption),
      );
    } catch (e) {
      debugPrint("Product image share failed, falling back to text-only: $e");
      await SharePlus.instance.share(ShareParams(text: caption));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    // Gate on the ACTIVE discount so an expired/ended campaign reverts to
    // full price with no lingering discount.
    final discounted = product.activeDiscountedPrice;
    final hasDiscount = discounted != null && discounted > 0;
    final inStock = product.availableStock > 0;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Everything from the carousel through the availability banner is
          // wrapped for share-image capture (see _shareProduct).
          RepaintBoundary(
            key: _shareCaptureKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Swipable lazy image carousel + share action
          Stack(
            children: [
              StorefrontDetailsCarousel(product: product),
              if (widget.storeSlug != null)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: _ShareButton(onTap: _shareProduct),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Name
          Text(
            product.name,
            style: GoogleFonts.inter(
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
              color: KorraColors.textDark,
              height: 1.25,
            ),
          ),
          SizedBox(height: 8.h),

          // Price block
          if (hasDiscount)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(discounted),
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFA54600),
                  ),
                ),
                SizedBox(width: 8.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: Text(
                    currencyFormat.format(product.price),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  margin: EdgeInsets.only(bottom: 3.h),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3F2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    "-${((product.price - discounted) / product.price * 100).round()}% OFF",
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB42318),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              currencyFormat.format(product.price),
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFA54600),
              ),
            ),

          // Live countdown for a merchant-timed deal on this product
          if (widget.deal != null && widget.deal!.hasTimer) ...[
            SizedBox(height: 8.h),
            DealCountdownBadge(campaign: widget.deal!),
          ],
          SizedBox(height: 12.h),

          // Category + stock chips
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _chip(
                label: product.category.toUpperCase(),
                bg: const Color(0xFFFFF4ED),
                fg: const Color(0xFFA54600),
              ),
              if (!inStock)
                _chip(label: "OUT OF STOCK", bg: const Color(0xFFFEF3F2), fg: const Color(0xFFB42318))
              else if (product.availableStock < 5)
                _chip(
                  label: "ONLY ${product.availableStock} LEFT",
                  bg: const Color(0xFFFFF4ED),
                  fg: const Color(0xFFB95000),
                )
              else
                _chip(
                  label: "IN STOCK · ${product.availableStock}",
                  bg: KorraColors.successBg,
                  fg: KorraColors.successFg,
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Payment availability banner
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: product.allowReservation ? const Color(0xFFECFDF3) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  product.allowReservation ? Iconsax.shield_tick : Iconsax.info_circle,
                  color: product.allowReservation ? KorraColors.settleGreen : Colors.grey.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    product.allowReservation
                        ? "Installment Plan Available (Reserve this item now)"
                        : "Outright Purchase Only (Installment plans disabled for this item)",
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: product.allowReservation ? const Color(0xFF027A48) : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // Description
          Text(
            "Description",
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800, color: KorraColors.textDark),
          ),
          SizedBox(height: 6.h),
          Text(
            product.description.isNotEmpty ? product.description : "No description provided for this item.",
            style: GoogleFonts.inter(fontSize: 13.sp, color: KorraColors.textBody, height: 1.45),
          ),
          SizedBox(height: 22.h),

          // Variant quantity list (variant products): pick amounts across
          // multiple options (5 x XL, 2 x XXL) and add them all in one tap.
          if (product.hasVariants && inStock && !widget.readOnly) ...[
            VariantQuantityList(
              variants: product.variants,
              quantities: _variantQty,
              maxFor: (v) {
                final inCart = CartService.instance.quantityForVariant(
                    product.vendorId, product.id, v.label);
                return (v.stock - inCart).clamp(0, v.stock);
              },
              onChanged: (label, delta) {
                setState(() {
                  final next = (_variantQty[label] ?? 0) + delta;
                  if (next <= 0) {
                    _variantQty.remove(label);
                  } else {
                    _variantQty[label] = next;
                  }
                });
              },
            ),
            SizedBox(height: 16.h),
          ],

          // Quantity stepper (flat products only; hidden in read-only mode)
          if (!product.hasVariants && inStock && !widget.readOnly) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quantity",
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textDark,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stepperButton(
                        icon: Icons.remove,
                        enabled: _selectedQuantity > 1,
                        onTap: () => setState(() => _selectedQuantity--),
                      ),
                      Container(
                        constraints: BoxConstraints(minWidth: 40.w),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedQuantity.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: KorraColors.textDark,
                          ),
                        ),
                      ),
                      _stepperButton(
                        icon: Icons.add,
                        enabled: _selectedQuantity < _maxAdd,
                        onTap: () => setState(() => _selectedQuantity++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],

          // Actions: Add to Cart & Pay Installments (hidden in read-only mode)
          if (!widget.readOnly)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52.h,
                  child: Builder(builder: (context) {
                    final selectedVariantTotal =
                        _variantQty.values.fold(0, (a, b) => a + b);
                    final canAdd = product.hasVariants
                        ? selectedVariantTotal > 0
                        : inStock && _maxAdd > 0;
                    return OutlinedButton.icon(
                      onPressed: canAdd
                          ? () {
                              if (product.hasVariants) {
                                // One cart line per chosen variant, one tap.
                                for (final entry in _variantQty.entries) {
                                  widget.onAddToCart
                                      ?.call(product, entry.value, entry.key);
                                }
                                setState(() => _variantQty.clear());
                              } else {
                                widget.onAddToCart?.call(product,
                                    _selectedQuantity.clamp(1, _maxAdd), null);
                                setState(() => _selectedQuantity = 1);
                              }
                            }
                          : null,
                      icon: Icon(Iconsax.shopping_bag, size: 17.sp, color: const Color(0xFFA54600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFA54600), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      label: Text(
                        product.hasVariants
                            ? (selectedVariantTotal > 0
                                ? "Add to Cart ($selectedVariantTotal)"
                                : "Add to Cart")
                            : (_maxAdd <= 0 && inStock
                                ? "All stock in cart"
                                : "Add to Cart"),
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA54600),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (product.allowReservation) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: ElevatedButton.icon(
                      onPressed: inStock
                          ? () async {
                              if (product.hasVariants) {
                                // A plan reserves exactly one unit, so the
                                // customer picks the variant first.
                                final label = await showVariantChooser(
                                    context, product.variants);
                                if (label == null) return;
                                widget.onPayInstallments?.call(widget.rawDoc, label);
                              } else {
                                widget.onPayInstallments?.call(widget.rawDoc, null);
                              }
                            }
                          : null,
                      icon: Icon(Iconsax.calendar_tick, size: 17.sp, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA54600),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      label: Text(
                        "Pay Installments",
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _chip({required String label, required Color bg, required Color fg}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 32.w,
        width: 32.w,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: enabled ? KorraColors.textDark : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Circular glass share button overlaid on the product image carousel.
class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Iconsax.export_3, size: 16.sp, color: KorraColors.textDark),
      ),
    );
  }
}