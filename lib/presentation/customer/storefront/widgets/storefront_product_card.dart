// lib/presentation/customer/storefront/widgets/storefront_product_card.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/vendor/campaign_model.dart';
import 'storefront_card_image.dart';

/// Premium marketplace product card (Temu/Shein style).
///
/// Interactions:
/// * Tap → opens product details (via [onTap]).
/// * Mouse hover (web/desktop) cycles the gallery every ~1.1s and resets to
///   the first photo on exit.
/// * Finger "hover" (mobile): any touch that lands on the card — including a
///   scroll swipe in any direction — starts cycling via raw pointer tracking
///   ([Listener], not InkWell highlight, which scrolling cancels). Each move
///   is hit-tested against the card's live bounds, so when the finger (or the
///   scrolling card itself) slides away, cycling stops ON the current image;
///   touching it again resumes.
/// * The card lifts slightly (scale 1.02 + deeper shadow) while hovered or
///   touched for the classic premium-store feel.
class StorefrontProductCard extends StatefulWidget {
  final Product product;
  final DocumentSnapshot? rawDoc;
  final Function(Product, DocumentSnapshot?) onTap;

  /// Set true when the card sits in a FIXED-height container (e.g. the
  /// Featured strip): the image flexes to fill the leftover space so the
  /// name/price block is ALWAYS fully visible instead of overflowing.
  final bool fixedHeight;

  /// The store's running/upcoming timed campaign for this product, if any.
  final Campaign? deal;

  const StorefrontProductCard({
    super.key,
    required this.product,
    this.rawDoc,
    required this.onTap,
    this.fixedHeight = false,
    this.deal,
  });

  @override
  State<StorefrontProductCard> createState() => _StorefrontProductCardState();
}

class _StorefrontProductCardState extends State<StorefrontProductCard> {
  int _imageIndex = 0;
  bool _isLifted = false;
  Timer? _cycleTimer;

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _startCycle() {
    if (widget.product.images.length < 2 || _cycleTimer != null) return;
    // Advance immediately so the interaction feels responsive, then keep going
    setState(() => _imageIndex = (_imageIndex + 1) % widget.product.images.length);
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted) return;
      setState(() => _imageIndex = (_imageIndex + 1) % widget.product.images.length);
    });
  }

  void _stopCycle({bool reset = false}) {
    _cycleTimer?.cancel();
    _cycleTimer = null;
    if (reset && mounted && _imageIndex != 0) setState(() => _imageIndex = 0);
  }

  void _setLifted(bool lifted) {
    if (_isLifted != lifted && mounted) setState(() => _isLifted = lifted);
  }

  // ── Finger-hover tracking (touch) ─────────────────────────────────────────
  bool _fingerInside = false;

  bool _isPointerOverCard(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    final local = box.globalToLocal(globalPosition);
    return (Offset.zero & box.size).contains(local);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return; // mouse uses hover
    _fingerInside = true;
    _setLifted(true);
    _startCycle();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    // Hit-test against live bounds: works while the list scrolls under the
    // finger too, since the card's position is re-resolved on every move.
    final inside = _isPointerOverCard(event.position);
    if (inside == _fingerInside) return;
    _fingerInside = inside;
    _setLifted(inside);
    inside ? _startCycle() : _stopCycle(); // stop ON the current image
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _fingerInside = false;
    _setLifted(false);
    _stopCycle(); // finger left the screen — stay on the current image
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final hasDiscount = product.discountedPrice != null && product.discountedPrice! > 0;
    final soldOut = product.availableStock <= 0;

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: MouseRegion(
      onEnter: (_) {
        _setLifted(true);
        _startCycle();
      },
      onExit: (_) {
        _setLifted(false);
        _stopCycle(reset: true);
      },
      child: AnimatedScale(
        scale: _isLifted ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isLifted ? 0.10 : 0.05),
                blurRadius: _isLifted ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onTap(product, widget.rawDoc),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // min is essential for Masonry unequal sizing; in fixed-height
                  // strips the image flexes instead so details always fit.
                  mainAxisSize:
                      widget.fixedHeight ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (widget.fixedHeight)
                      Expanded(
                        child: StorefrontCardImage(
                          product: product,
                          imageIndex: _imageIndex,
                          soldOut: soldOut,
                          deal: widget.deal,
                          expand: true,
                        ),
                      )
                    else
                      StorefrontCardImage(
                        product: product,
                        imageIndex: _imageIndex,
                        soldOut: soldOut,
                        deal: widget.deal,
                      ),
                    _buildDetails(product, currencyFormat, hasDiscount, soldOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  // ── Details: name, description, price & stock ────────────────────────────
  Widget _buildDetails(
    Product product,
    NumberFormat currencyFormat,
    bool hasDiscount,
    bool soldOut,
  ) {
    return Padding(
      padding: EdgeInsets.all(10.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Name
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: KorraColors.textDark,
            ),
          ),
          SizedBox(height: 3.h),

          // Description
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5.sp,
              color: KorraColors.textMuted,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),

          // Price Row (Handles Discount vs Regular Pricing)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: hasDiscount
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  currencyFormat.format(product.discountedPrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFA54600),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              // Discount percentage bubble badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3F2),
                                  borderRadius: BorderRadius.circular(3.r),
                                ),
                                child: Text(
                                  "-${((product.price - product.discountedPrice!) / product.price * 100).round()}%",
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB42318),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            currencyFormat.format(product.price),
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        currencyFormat.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFA54600),
                        ),
                      ),
              ),

              // Low-stock urgency nudge (sold out is shown on the image veil)
              if (!soldOut && product.availableStock < 5)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4ED),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    "Only ${product.availableStock} left",
                    style: GoogleFonts.inter(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB95000),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}