import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import 'package:korra/config/constants/colors.dart';

import '../../../../logic/bloc/customer/link/link_bloc.dart';
import '../../../../logic/bloc/customer/link/link_state.dart';

class NewPlanSheet extends StatefulWidget {
  final void Function(String value) onSubmit;
  const NewPlanSheet({super.key, required this.onSubmit});

  @override
  State<NewPlanSheet> createState() => _NewPlanSheetState();
}

class _NewPlanSheetState extends State<NewPlanSheet> {
  final TextEditingController _linkCtrl = TextEditingController();
  static const _brand = Color(0xFFA54600);
  bool _hasClipboardContent = false;
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
    _linkCtrl.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _linkCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _linkCtrl.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null &&
        (data!.text!.startsWith('http') || data.text!.startsWith('www'))) {
      setState(() => _hasClipboardContent = true);
    }
  }

  void _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _linkCtrl.text = data!.text!;
      });
    }
  }

  void _submitLink() {
    if (_linkCtrl.text.trim().isNotEmpty) {
      HapticFeedback.mediumImpact(); // Tactile confirmation
      widget.onSubmit(_linkCtrl.text.trim());
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the keyboard height
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      // 2. Add padding for the keyboard
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        // 3. Wrap in ScrollView to prevent overflow
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.only(bottom: 20.h),
                ),
              ),

              // Title
              Text(
                'New Reservation',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Paste a product link or code from any supported store or scan a QR code.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF667085),
                ),
              ),
              SizedBox(height: 20.h),

              // Input Field
              Container(
                height: 54.h,
                decoration: BoxDecoration(
                  color: _isFocused ? Colors.white : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 0.h, 0.w, 0.h),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.link_1,
                      color: Colors.grey.shade400,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _linkCtrl,
                        // 4. Important: Connect focus to keyboard action
                        autofocus: true,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.go,
                        cursorColor: KorraColors.brand,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste link or code here...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                          border: InputBorder.none,
                          isDense: true,
                          // Animated Submit Button inside the field
                          suffixIcon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: _hasText
                                ? IconButton(
                                    key: const ValueKey('submit'),
                                    onPressed: _submitLink,
                                    icon: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: const BoxDecoration(
                                        color: KorraColors.brand,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(), // Empty when no text
                          ),
                        ),
                        onSubmitted: (_) => _submitLink(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),

              // Loading indicator for Link processing
              BlocBuilder<LinkBloc, LinkState>(
                builder: (context, state) {
                  final showLoader =
                      state.status == LinkStatus.validating ||
                      state.status == LinkStatus.loadingProduct;

                  return showLoader
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KorraColors.brand,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  state.message ?? '',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13.sp,
                                    fontStyle: FontStyle.italic,
                                    color: KorraColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),

              SizedBox(height: 16.h),
              SizedBox(height: 24.h),
              // // Secondary Actions
              // Row(
              //   children: [
              //     _buildSecondaryAction(
              //       icon: Iconsax.scan_barcode,
              //       label: "Scan QR",
              //       onTap: () {},
              //     ),
              //     SizedBox(width: 12.w),
              //     _buildSecondaryAction(
              //       icon: Iconsax.shop,
              //       label: "Browse Stores",
              //       onTap: () {},
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24.sp, color: const Color(0xFF344054)),
              SizedBox(height: 8.h),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF344054),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
