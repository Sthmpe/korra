import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ProductSearchField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ProductSearchField({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextField(
        controller: _ctl,
        onChanged: widget.onChanged,
        style: GoogleFonts.inter(fontSize: 13.5.sp),
        decoration: InputDecoration(
          hintText: 'Search products',
          hintStyle: GoogleFonts.inter(fontSize: 13.5.sp, color: const Color(0xFF8B8B8B)),
          prefixIcon: Icon(Iconsax.search_normal_1, size: 18.sp),
          suffixIcon: _ctl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, size: 18.sp),
                  onPressed: () {
                    _ctl.clear();
                    widget.onClear();
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }
}
