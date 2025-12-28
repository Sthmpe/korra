import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';

class ReservationSearchBar extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const ReservationSearchBar({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<ReservationSearchBar> createState() => _ReservationSearchBarState();
}

class _ReservationSearchBarState extends State<ReservationSearchBar> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h, // Slightly taller for premium feel
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1.5), // Subtle gray border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(left: 14.w),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF667085), size: 20),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _c,
              onChanged: (value) {
                widget.onChanged(value);
                setState(() {}); // Update to show/hide clear icon
              },
              textInputAction: TextInputAction.search,
              cursorColor: KorraColors.brand,
              style: GoogleFonts.inter(
                fontSize: 14.sp, 
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D2939),
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search customer, product or code...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.sp, 
                  color: const Color(0xFF98A2B3),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (_c.text.isNotEmpty) 
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact(); // Modern feedback
                _c.clear();
                widget.onClear();
                setState(() {});
              },
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Color(0xFF667085), size: 16),
              ),
            ),
        ],
      ),
    );
  }
}