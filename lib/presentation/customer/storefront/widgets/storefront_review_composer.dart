// lib/presentation/customer/storefront/widgets/storefront_review_composer.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/constants/colors.dart';
import '../../../../data/models/vendor/vendor_review.dart';

/// Write-a-review card shown only to customers who have purchased from the
/// store. Rating is required, the comment is OPTIONAL (a customer may rate
/// without writing anything).
///
/// * No existing review → "Rate your experience" straight into the composer.
/// * Existing review → a summary of their review with a "Change review?"
///   prompt; entering edit mode keeps their stars but starts the comment
///   BLANK — whatever they type replaces what they said before.
class StorefrontReviewComposer extends StatefulWidget {
  final VendorReview? existing;
  final Future<void> Function(double rating, String comment) onSubmit;

  const StorefrontReviewComposer({
    super.key,
    required this.existing,
    required this.onSubmit,
  });

  @override
  State<StorefrontReviewComposer> createState() => _StorefrontReviewComposerState();
}

class _StorefrontReviewComposerState extends State<StorefrontReviewComposer> {
  final TextEditingController _commentController = TextEditingController();
  late bool _editing; // composing right now (always true when no existing review)
  double _rating = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _editing = widget.existing == null;
    _rating = widget.existing?.rating ?? 0;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating <= 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F4),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: _editing ? _composer() : _existingSummary(),
    );
  }

  // ── Existing review + "change?" prompt ─────────────────────────────────
  Widget _existingSummary() {
    final existing = widget.existing!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your review",
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: KorraColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < existing.rating.round()
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: Colors.amber,
              size: 18.sp,
            );
          }),
        ),
        if (existing.comment.trim().isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            existing.comment,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: KorraColors.textBody,
              height: 1.4,
            ),
          ),
        ],
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Text(
                "Do you want to change your review?",
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: KorraColors.textMuted,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _editing = true;
                _rating = existing.rating;
                _commentController.clear(); // typing replaces the old comment
              }),
              icon: Icon(Iconsax.edit_2, size: 14.sp, color: KorraColors.brand),
              label: Text(
                "Change review",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: KorraColors.brand,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Composer (new review, or replacing the old one) ────────────────────
  Widget _composer() {
    final isUpdate = widget.existing != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUpdate ? "Update your review" : "Rate your experience",
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: KorraColors.textDark,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          isUpdate
              ? "Your new rating and comment will replace the previous one."
              : "You bought from this store let others know how it went.",
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: KorraColors.textMuted,
          ),
        ),
        SizedBox(height: 12.h),

        // Star selector
        Row(
          children: List.generate(5, (i) {
            final filled = i < _rating;
            return GestureDetector(
              onTap: () => setState(() => _rating = (i + 1).toDouble()),
              child: Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 28.sp,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 12.h),

        // Optional comment
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 2,
            maxLength: 300,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: KorraColors.textDark,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: "Share a few words (optional)",
              hintStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                color: KorraColors.textHint,
              ),
              counterStyle: GoogleFonts.inter(
                fontSize: 9.sp,
                color: KorraColors.textHint,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        Row(
          children: [
            if (isUpdate)
              TextButton(
                onPressed: () => setState(() => _editing = false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: KorraColors.textMuted,
                  ),
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _rating > 0 && !_submitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: KorraColors.brand,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFEAECF0),
                elevation: 0,
                // Global theme forces minimumSize width = infinity; inside a
                // Row that is an invalid constraint — size to content instead.
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              icon: _submitting
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Iconsax.send_1, size: 14.sp),
              label: Text(
                isUpdate ? "Update review" : "Submit review",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
