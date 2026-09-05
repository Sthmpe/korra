// lib/presentation/customer/storefront/widgets/ai_review_summary_box.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/constants/colors.dart';

/// Collapsible "AI review summary" box shown at the top of the customer
/// feedback list. Calls the `ai-review-summary` Supabase function, which is
/// currently a stub and always reports the service as unavailable, so the box
/// still renders so the feature is visible and ready for when a real model
/// is wired in.
class AiReviewSummaryBox extends StatefulWidget {
  final String vendorId;

  const AiReviewSummaryBox({super.key, required this.vendorId});

  @override
  State<AiReviewSummaryBox> createState() => _AiReviewSummaryBoxState();
}

class _AiReviewSummaryBoxState extends State<AiReviewSummaryBox> {
  bool _dismissed = false;
  bool _expanded = true;
  bool _loading = true;
  bool _available = false;
  String _message = "AI currently unavailable";
  String? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'ai-review-summary',
        body: {'vendorId': widget.vendorId},
      );
      final data = res.data;
      if (mounted && data is Map) {
        setState(() {
          _available = data['available'] == true;
          _summary = data['summary']?.toString();
          _message = data['message']?.toString() ?? "AI currently unavailable";
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('AI review summary fetch failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFFFE1CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10.r),
            child: Row(
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA54600),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.magic_star, size: 15.sp, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "AI review summary",
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: KorraColors.textDark,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  size: 16.sp,
                  color: KorraColors.textMuted,
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () => setState(() => _dismissed = true),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(Iconsax.close_circle, size: 16.sp, color: KorraColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            SizedBox(height: 10.h),
            _loading
                ? Row(
                    children: [
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: KorraColors.brand),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Summarizing customer feedback...",
                        style: GoogleFonts.inter(fontSize: 12.sp, color: KorraColors.textMuted),
                      ),
                    ],
                  )
                : Text(
                    _available && _summary != null && _summary!.isNotEmpty
                        ? _summary!
                        : _message,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      height: 1.5,
                      fontWeight: _available ? FontWeight.w500 : FontWeight.w600,
                      color: _available ? KorraColors.textBody : KorraColors.textMuted,
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
