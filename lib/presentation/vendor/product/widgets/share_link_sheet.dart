import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/vendor/product/vendor_products_state.dart';
import 'product_share_card.dart'; // Import the new card file

class ShareLinkSheet extends StatefulWidget {
  final ProductItem product;

  const ShareLinkSheet({
    super.key,
    required this.product,
  });

  static Future<void> show(BuildContext context, ProductItem product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => ShareLinkSheet(product: product),
    );
  }

  @override
  State<ShareLinkSheet> createState() => _ShareLinkSheetState();
}

class _ShareLinkSheetState extends State<ShareLinkSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;

  // --- 📸 CAPTURE AND SHARE LOGIC ---
  Future<void> _shareImage() async {
    setState(() => _isSharing = true);

    try {
      // 1. Wait a tiny bit to ensure the widget is fully painted (images loaded)
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Capture the RenderObject
      RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      // 3. Convert to Image Data (3.0x pixel ratio for high quality)
      ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 4. Save to Temporary File
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/korra_${widget.product.code}.png').create();
      await imagePath.writeAsBytes(pngBytes);

      // 5. Share via System Sheet
      final caption = "🔥 New Drop Alert!\n"
          "${widget.product.name} — ${widget.product.priceText}\n"
          "Don't wait. Lock this price now on Korra.\n\n"
          "Code: *${widget.product.code}*";

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: caption,
      );
      
      // Optional: Close sheet after successful share
      // if (mounted) Navigator.pop(context); 

    } catch (e) {
      debugPrint("Share Error: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            "Share Product",
            style: GoogleFonts.inter(
              fontSize: 18.sp, 
              fontWeight: FontWeight.w700,
              color: const Color(0xFF101828),
            ),
          ),
          SizedBox(height: 24.h),

          // 2. THE FLYER CARD (We render it here so user sees what they share)
          // We wrap it in a scroll view just in case the screen is small
          Flexible(
            child: SingleChildScrollView(
              child: ProductShareCard(
                product: widget.product,
                repaintKey: _repaintKey,
              ),
            ),
          ),

          SizedBox(height: 30.h),

          // 3. SHARE BUTTON
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: FilledButton.icon(
              onPressed: _isSharing ? null : _shareImage,
              style: FilledButton.styleFrom(
                backgroundColor: KorraColors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              icon: _isSharing
                  ? Container(
                      width: 20, height: 20, 
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Icon(Icons.share, size: 22.sp),
              label: Text(
                _isSharing ? "Generating..." : "Share Image",
                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // 4. Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}