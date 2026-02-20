import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart'; // Cleaner icons

import '../../../../config/constants/colors.dart';

class LinkInput extends StatefulWidget {
  final void Function(String value) onSubmit;
  final void Function(String value) onScan;
  
  const LinkInput({
    super.key, 
    required this.onSubmit, 
    required this.onScan
  });

  @override
  State<LinkInput> createState() => _LinkInputState();
}

class _LinkInputState extends State<LinkInput> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasText = _ctrl.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_ctrl.text.trim().isNotEmpty) {
      HapticFeedback.mediumImpact(); // Tactile confirmation
      widget.onSubmit(_ctrl.text.trim());
      _focusNode.unfocus();
    }
  }

  void _handleScan() {
    HapticFeedback.lightImpact();
    widget.onScan(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // --- THE INPUT FIELD ---
          Expanded(
            child: Container(
              //duration: const Duration(milliseconds: 200),
              height: 54.h, // Taller, friendlier touch target
              decoration: BoxDecoration(
                // Soft grey fill by default, White when focused
                color: _isFocused ? Colors.white : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(16.r), // Modern "Squircle" feel
                border: Border.all(
                  // Subtle brand border only when active
                  color: _isFocused ? KorraColors.brand : Colors.transparent,
                  width: 1.3,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: KorraColors.brand.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                      BoxShadow(
                          blurRadius: 0,
                        )
                    ],
              ),
              child: Center(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _handleSubmit(),
                  style: GoogleFonts.inter(
                    fontSize: 15.sp, // Larger, legible font
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1B1B),
                  ),
                  cursorColor: KorraColors.brand,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Paste link or code',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF), // Cool grey
                    ),
                    prefixIcon: Icon(
                      Iconsax.link_2, 
                      size: 20.sp, 
                      color: _isFocused ? KorraColors.brand : const Color(0xFF9CA3AF),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 48.w),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16.r), 
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    
                    // Animated Submit Button inside the field
                    suffixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => 
                          ScaleTransition(scale: anim, child: child),
                      child: _hasText
                          ? IconButton(
                              key: const ValueKey('submit'),
                              onPressed: _handleSubmit,
                              icon: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: const BoxDecoration(
                                  color: KorraColors.brand,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded, 
                                  size: 16.sp, 
                                  color: Colors.white
                                ),
                              ),
                            )
                          : const SizedBox.shrink(), // Empty when no text
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // --- THE SCAN BUTTON ---
          // Matches height and style but distinct
          Material(
            color: const Color(0xFFF2F2F7), // Same background as inactive input
            borderRadius: BorderRadius.circular(16.r),
            child: InkWell(
              onTap: _handleScan,
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                height: 54.h,
                width: 54.h, // Perfectly square
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent, width: 1.5),
                ),
                child: Icon(
                  Iconsax.scan, 
                  size: 24.sp, 
                  color: const Color(0xFF1B1B1B), // Dark icon for contrast
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}