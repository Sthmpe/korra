import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/vendor/vendor_reservation.dart';

class ReservationTile extends StatelessWidget {
  final VendorReservation data;
  final VoidCallback onTap;                 // open details
  final VoidCallback onArrangeDelivery;     // completed only
  const ReservationTile({
    super.key,
    required this.data,
    required this.onTap,
    required this.onArrangeDelivery,
  });

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFEAE6E2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ProductImage(url: data.imageUrl),
            SizedBox(width: 10.w),
            Expanded(child: _Info(data: data, onArrangeDelivery: onArrangeDelivery)),
          ]),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;
  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: 72.w, height: 72.w,
        child: Image.network(
          url, fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFFF3EFEA),
              child: Center(
                child: SizedBox(
                  width: 16.w, height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 1.8),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFF3EFEA),
            child: const Icon(Icons.broken_image_outlined, color: Color(0xFF8B8B8B)),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final VendorReservation data;
  final VoidCallback onArrangeDelivery;
  const _Info({required this.data, required this.onArrangeDelivery});

  static const _brand = Color(0xFFA54600);

  @override
  Widget build(BuildContext context) {
    final isCancelled = data.status == ReservationStatus.cancelled;
    final isCompleted = data.status == ReservationStatus.completed;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Title + copy id
      Row(children: [
        Expanded(
          child: Text(
            data.productTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1B)),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Clipboard.setData(ClipboardData(text: data.id));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied ID ${data.id}', style: GoogleFonts.inter(fontSize: 13.sp))),
            );
          },
          child: Icon(Icons.copy, size: 16.sp, color: const Color(0xFF8B8B8B)),
        ),
      ]),
      SizedBox(height: 4.h),

      // Meta: customer • created • SKU
      Text(
        '${data.customerName} • ${data.createdAtText} • ${data.sku}',
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E5E5E)),
      ),
      SizedBox(height: 6.h),

      // Price row
      Row(children: [
        Expanded(
          child: Text(
            '${data.quantity} × ${data.unitPriceText}',
            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        Text(
          data.totalText,
          style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ]),

      if (!isCancelled) ...[
        SizedBox(height: 8.h),
        // Progress + status badge
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999.r),
              child: LinearProgressIndicator(
                minHeight: 6.h,
                value: data.progress01,
                backgroundColor: const Color(0xFFF0ECE8),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFA54600)),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          if (data.overdue)
            const _Badge(text: 'Overdue', c: Color(0xFFD92D20))
          else
            _Badge(text: data.autoPay ? 'AutoPay' : 'On schedule', c: _brand),
        ]),
        SizedBox(height: 6.h),
        // Next due + remaining
        Text(
          isCompleted ? 'Paid off' : '${data.nextDueText} • ${data.remainingText}',
          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1B1B1B)),
        ),
      ] else ...[
        SizedBox(height: 8.h),
        const _Badge(text: 'Cancelled', c: Color(0xFF8B8B8B)),
      ],

      // Tiny link for completed -> arrange delivery
      if (isCompleted) ...[
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onArrangeDelivery,
          child: Text(
            'Arrange delivery',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: _brand,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String text; final Color c;
  const _Badge({required this.text, required this.c});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: c),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
