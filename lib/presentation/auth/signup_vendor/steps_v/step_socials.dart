import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';

class StepSocials extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepSocials({super.key, required this.formKey});

  @override
  State<StepSocials> createState() => _StepSocialsState();
}

class _StepSocialsState extends State<StepSocials> {
  // Controllers
  late final TextEditingController _instaCtl;
  late final TextEditingController _twitterCtl;
  late final TextEditingController _fbCtl;
  late final TextEditingController _tiktokCtl;
  late final TextEditingController _webCtl;
  late final TextEditingController _waCtl;
  late final TextEditingController _otherCtl;

  // Focus Nodes
  final _instaFocus = FocusNode();
  final _twitterFocus = FocusNode();
  final _fbFocus = FocusNode();
  final _tiktokFocus = FocusNode();
  final _webFocus = FocusNode();
  final _waFocus = FocusNode();
  final _otherFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    
    // Initialize and listen (Assuming new events exist in your Bloc)
    _instaCtl = TextEditingController(text: s.instagram)..addListener(() { _on(InstagramChanged(_instaCtl.text)); _updateCount(); });
    _twitterCtl = TextEditingController(text: s.twitter)..addListener(() { _on(TwitterChanged(_twitterCtl.text)); _updateCount(); });
    _fbCtl = TextEditingController(text: s.facebook)..addListener(() { _on(FacebookChanged(_fbCtl.text)); _updateCount(); });
    _tiktokCtl = TextEditingController(text: s.tiktok)..addListener(() { _on(TiktokChanged(_tiktokCtl.text)); _updateCount(); });
    
    // New Fields
    _webCtl = TextEditingController(text: s.website)..addListener(() { _on(WebsiteChanged(_webCtl.text)); _updateCount(); });
    _waCtl = TextEditingController(text: s.whatsappGroup)..addListener(() { _on(WhatsappGroupChanged(_waCtl.text)); _updateCount(); });
    _otherCtl = TextEditingController(text: s.otherLink)..addListener(() { _on(OtherLinkChanged(_otherCtl.text)); _updateCount(); });
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);

  // Local state for UI progress bar
  int _filledCount = 0;

  void _updateCount() {
    int count = 0;
    if (_instaCtl.text.trim().isNotEmpty) count++;
    if (_twitterCtl.text.trim().isNotEmpty) count++;
    if (_fbCtl.text.trim().isNotEmpty) count++;
    if (_tiktokCtl.text.trim().isNotEmpty) count++;
    if (_webCtl.text.trim().isNotEmpty) count++;
    if (_waCtl.text.trim().isNotEmpty) count++;
    if (_otherCtl.text.trim().isNotEmpty) count++;
    
    if (_filledCount != count) {
      setState(() => _filledCount = count);
    }
  }

  @override
  void dispose() {
    _instaCtl.dispose(); _twitterCtl.dispose(); _fbCtl.dispose(); _tiktokCtl.dispose(); _webCtl.dispose(); _waCtl.dispose(); _otherCtl.dispose();
    _instaFocus.dispose(); _twitterFocus.dispose(); _fbFocus.dispose(); _tiktokFocus.dispose(); _webFocus.dispose(); _waFocus.dispose(); _otherFocus.dispose();
    super.dispose();
  }

  // Global Validator Logic
  String? _validateRequirement(String? val) {
    if (_filledCount < 3) return 'Add more links';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Presence',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Where can customers verify your business? Please provide at least 3 distinct links.',
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
            ),
            SizedBox(height: 24.h),

            // --- PROGRESS INDICATOR ---
            _RequirementProgress(count: _filledCount, required: 3),
            
            SizedBox(height: 32.h),

            // --- 1. INSTAGRAM ---
            _SocialInput(
              controller: _instaCtl,
              focusNode: _instaFocus,
              label: 'Instagram',
              hint: 'username',
              icon: MdiIcons.instagram,
              brandColor: const Color(0xFFE1306C),
              prefixText: '@',
              validator: _validateRequirement,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_twitterFocus),
            ),
            SizedBox(height: 24.h),

            // --- 2. TWITTER / X ---
            _SocialInput(
              controller: _twitterCtl,
              focusNode: _twitterFocus,
              label: 'Twitter / X',
              hint: 'username',
              icon: MdiIcons.twitter,
              brandColor: Colors.black,
              prefixText: '@',
              validator: _validateRequirement,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_tiktokFocus),
            ),
            SizedBox(height: 24.h),

            // --- 3. TIKTOK ---
            _SocialInput(
              controller: _tiktokCtl,
              focusNode: _tiktokFocus,
              label: 'TikTok',
              hint: 'username',
              icon: Icons.tiktok, 
              brandColor: Colors.black,
              prefixText: '@',
              validator: _validateRequirement,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_waFocus),
            ),
            SizedBox(height: 24.h),

            // --- 4. WHATSAPP GROUP ---
            _SocialInput(
              controller: _waCtl,
              focusNode: _waFocus,
              label: 'WhatsApp Group',
              hint: 'chat.whatsapp.com/...',
              icon: MdiIcons.whatsapp,
              brandColor: const Color(0xFF25D366),
              inputType: TextInputType.url,
              validator: _validateRequirement,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_webFocus),
            ),
            SizedBox(height: 24.h),

            // --- 5. WEBSITE ---
            _SocialInput(
              controller: _webCtl,
              focusNode: _webFocus,
              label: 'Website / Store Link',
              hint: 'www.yourstore.com',
              icon: Iconsax.global,
              brandColor: Colors.blue.shade700,
              inputType: TextInputType.url,
              validator: _validateRequirement,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_fbFocus),
            ),
            SizedBox(height: 24.h),

            // --- 6. FACEBOOK ---
            _SocialInput(
              controller: _fbCtl,
              focusNode: _fbFocus,
              label: 'Facebook Page',
              hint: 'facebook.com/page',
              icon: MdiIcons.facebook,
              brandColor: const Color(0xFF1877F2),
              inputType: TextInputType.url,
              validator: _validateRequirement,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_otherFocus),
            ),
            SizedBox(height: 24.h),

            // --- 7. OTHERS ---
            _SocialInput(
              controller: _otherCtl,
              focusNode: _otherFocus,
              label: 'Other (Linktree, etc)',
              hint: 'https://...',
              icon: Iconsax.link_1,
              brandColor: Colors.grey.shade700,
              inputType: TextInputType.url,
              validator: _validateRequirement,
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REQUIREMENT PROGRESS BAR (Gamification)
// -----------------------------------------------------------------------------
class _RequirementProgress extends StatelessWidget {
  final int count;
  final int required;

  const _RequirementProgress({required this.count, required this.required});

  @override
  Widget build(BuildContext context) {
    final progress = (count / required).clamp(0.0, 1.0);
    final isComplete = count >= required;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED), // Green vs Orange bg
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFFFEDD5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete ? "Requirement Met" : "$count of $required Links Added",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isComplete ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                ),
              ),
              if (isComplete)
                Icon(Iconsax.tick_circle, color: const Color(0xFF15803D), size: 18.sp),
            ],
          ),
          SizedBox(height: 10.h),
          
          // Bar
          Stack(
            children: [
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                widthFactor: progress,
                child: Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
            ],
          ),
          
          if (!isComplete)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                "Add ${required - count} more to continue.",
                style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFFC2410C)),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM SOCIAL INPUT (Reused from previous, added Validator)
// -----------------------------------------------------------------------------
class _SocialInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final Color brandColor;
  final String? prefixText;
  final TextInputType inputType;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _SocialInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.brandColor,
    this.prefixText,
    this.inputType = TextInputType.text,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_SocialInput> createState() => _SocialInputState();
}

class _SocialInputState extends State<_SocialInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  void _handleFocus() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 16.sp, color: widget.brandColor),
            SizedBox(width: 8.w),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.white
                : const Color(0xFFF7F7F7), // Very subtle grey when inactive
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isFocused
                  ? KorraColors.brand
                  : const Color(0xFFE5E5E5), // Brand or light grey
              width: 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: KorraColors.brand.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.inputType,
            onFieldSubmitted: (v) {
              HapticFeedback.selectionClick();
              widget.onSubmitted?.call(v);
            },
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B1B1B),
            ),
            cursorColor: KorraColors.brand,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFAAAAAA), // Softer placeholder
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r), 
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              // Hide error here, we can show it below if needed, or keep it simple
              errorStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}