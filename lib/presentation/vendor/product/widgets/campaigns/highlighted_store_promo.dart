// lib/presentation/vendor/product/widgets/campaigns/highlighted_store_promo.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../config/constants/sizes.dart';
import '../../../../../data/models/vendor/vendor_visibility.dart';
import '../../../../shared/widgets/show_app_snackbar.dart';

class HighlightedStorePromo extends StatefulWidget {
  final String vendorId;
  final VendorVisibility visibility;

  const HighlightedStorePromo({
    super.key,
    required this.vendorId,
    required this.visibility,
  });

  @override
  State<HighlightedStorePromo> createState() => _HighlightedStorePromoState();
}

class _HighlightedStorePromoState extends State<HighlightedStorePromo> {
  late bool _isHighlightedLocal;

  @override
  void initState() {
    super.initState();
    _isHighlightedLocal = widget.visibility.isHighlighted;
  }

  @override
  void didUpdateWidget(covariant HighlightedStorePromo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibility.isHighlighted != widget.visibility.isHighlighted) {
      _isHighlightedLocal = widget.visibility.isHighlighted;
    }
  }

  Future<void> _toggleHighlight(bool value) async {
    setState(() {
      _isHighlightedLocal = value;
    });

    try {
      await FirebaseFirestore.instance
          .collection('vendor_visibility')
          .doc(widget.vendorId)
          .set({'isHighlighted': value}, SetOptions(merge: true));
          
      if (mounted) {
        showAppSnackbar(
          value ? "Highlighted Store enabled!" : "Highlighted Store disabled.",
          SnackbarType.success,
        );
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        _isHighlightedLocal = !value;
      });
      if (mounted) {
        showAppSnackbar("Failed to update Highlighted Store status: $e", SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4ED), Color(0xFFFFEAD6)],
        ),
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        // Removed border outline to keep it clean and borderless
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: const Color(0xFFA54600), size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Highlighted Store Status",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: const Color(0xFFA54600),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Appear at the top of customer feeds. Try for free during beta!",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isHighlightedLocal,
            onChanged: _toggleHighlight,
            activeColor: const Color(0xFFA54600),
          ),
        ],
      ),
    );
  }
}
