import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
      height: 44.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEAE6E2)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(children: [
        const Icon(Icons.search_rounded, color: Color(0xFF8B8B8B)),
        SizedBox(width: 8.w),
        Expanded(
          child: TextField(
            controller: _c,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Search customer, product or SKU',
              hintStyle: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF8B8B8B)),
            ),
          ),
        ),
        if (_c.text.isNotEmpty) GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _c.clear();
            widget.onClear();
            setState(() {});
          },
          child: const Icon(Icons.close_rounded, color: Color(0xFF8B8B8B)),
        ),
      ]),
    );
  }
}
