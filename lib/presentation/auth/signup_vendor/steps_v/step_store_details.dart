import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';
import '../../../../config/constants/vendor_categories.dart';
import '../../../../config/validators/validators.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_bloc.dart';
import '../../../../logic/bloc/auth/signup_vendor/signup_vendor_event.dart';

class StepStoreDetails extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const StepStoreDetails({super.key, required this.formKey});

  @override
  State<StepStoreDetails> createState() => _StepStoreDetailsState();
}

class _StepStoreDetailsState extends State<StepStoreDetails> {
  // --- Store & Location Controllers ---
  late final TextEditingController _storeCtl;
  late final TextEditingController _addrCtl;
  late final TextEditingController _cityCtl;
  late final TextEditingController _stateCtl;
  late final TextEditingController _mapCtl;

  // --- Social Controllers ---
  late final TextEditingController _instaCtl;
  late final TextEditingController _twitterCtl;
  late final TextEditingController _fbCtl;
  late final TextEditingController _tiktokCtl;
  late final TextEditingController _webCtl;
  late final TextEditingController _waCtl;
  late final TextEditingController _otherCtl;

  // --- Focus Nodes ---
  final _storeFocus = FocusNode();
  final _addrFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  
  final _instaFocus = FocusNode();
  final _twitterFocus = FocusNode();
  final _fbFocus = FocusNode();
  final _tiktokFocus = FocusNode();
  final _webFocus = FocusNode();
  final _waFocus = FocusNode();
  final _otherFocus = FocusNode();

  // --- Local State for Gamification ---
  int _filledCount = 0;

  @override
  void initState() {
    super.initState();
    final s = context.read<SignupVendorBloc>().state;
    
    // Store & Location Init
    _storeCtl = TextEditingController(text: s.storeName)..addListener(() => _on(StoreNameChanged(_storeCtl.text)));
    _addrCtl = TextEditingController(text: s.address)..addListener(() => _on(AddressChanged(_addrCtl.text)));
    _cityCtl = TextEditingController(text: s.city)..addListener(() => _on(CityChanged(_cityCtl.text)));
    _stateCtl = TextEditingController(text: s.stateName)..addListener(() => _on(StateChangedVD(_stateCtl.text)));
    _mapCtl = TextEditingController(text: s.mapsLink)..addListener(() => _on(MapsLinkChanged(_mapCtl.text)));

    // Socials Init (With Counter Listener)
    _instaCtl = TextEditingController(text: s.instagram)..addListener(() { _on(InstagramChanged(_instaCtl.text)); _updateCount(); });
    _twitterCtl = TextEditingController(text: s.twitter)..addListener(() { _on(TwitterChanged(_twitterCtl.text)); _updateCount(); });
    _fbCtl = TextEditingController(text: s.facebook)..addListener(() { _on(FacebookChanged(_fbCtl.text)); _updateCount(); });
    _tiktokCtl = TextEditingController(text: s.tiktok)..addListener(() { _on(TiktokChanged(_tiktokCtl.text)); _updateCount(); });
    _webCtl = TextEditingController(text: s.website)..addListener(() { _on(WebsiteChanged(_webCtl.text)); _updateCount(); });
    _waCtl = TextEditingController(text: s.whatsappGroup)..addListener(() { _on(WhatsappGroupChanged(_waCtl.text)); _updateCount(); });
    _otherCtl = TextEditingController(text: s.otherLink)..addListener(() { _on(OtherLinkChanged(_otherCtl.text)); _updateCount(); });
    
    // Initial count check
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCount());
  }

  void _on(SignupVendorEvent e) => context.read<SignupVendorBloc>().add(e);

  void _updateCount() {
    int count = 0;
    if (_instaCtl.text.trim().isNotEmpty) count++;
    if (_twitterCtl.text.trim().isNotEmpty) count++;
    if (_fbCtl.text.trim().isNotEmpty) count++;
    if (_tiktokCtl.text.trim().isNotEmpty) count++;
    if (_webCtl.text.trim().isNotEmpty) count++;
    if (_waCtl.text.trim().isNotEmpty) count++;
    if (_otherCtl.text.trim().isNotEmpty) count++;
    
    if (_filledCount != count) setState(() => _filledCount = count);
  }
  
  String? _validateLinks(String? val) {
    if (_filledCount < 3) return '3 links required';
    return null;
  }

  @override 
  void dispose() { 
    _storeCtl.dispose(); _addrCtl.dispose(); _cityCtl.dispose(); _stateCtl.dispose(); _mapCtl.dispose();
    _instaCtl.dispose(); _twitterCtl.dispose(); _fbCtl.dispose(); _tiktokCtl.dispose(); _webCtl.dispose(); _waCtl.dispose(); _otherCtl.dispose();
    
    _storeFocus.dispose(); _addrFocus.dispose(); _cityFocus.dispose(); _stateFocus.dispose();
    _instaFocus.dispose(); _twitterFocus.dispose(); _fbFocus.dispose(); _tiktokFocus.dispose(); _webFocus.dispose(); _waFocus.dispose(); _otherFocus.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SignupVendorBloc>().state;
    final needsPhysical = s.presence == Presence.physical || s.presence == Presence.both;

    String? _requiredIfPhysical(String? v) {
      if (!needsPhysical) return null;
      if (v == null || v.trim().isEmpty) return 'Required';
      return null;
    }

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
              'Store Details',
              style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF111111), letterSpacing: -0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tell us about your shop and where customers can find you.',
              style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF666666), height: 1.4),
            ),
            SizedBox(height: 32.h),

            // ----------------------------------------------------------
            // SECTION 1: BASIC INFO
            // ----------------------------------------------------------
            _PremiumInput(
              controller: _storeCtl,
              focusNode: _storeFocus,
              label: 'Store Name',
              hint: 'e.g. Amazing Gadgets',
              icon: Iconsax.shop,
              textCapitalization: TextCapitalization.words,
              validator: (v) => KorraValidators.name(v, field: 'Store name'),
            ),
            SizedBox(height: 24.h),

            // Categories
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Categories', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
                Text('Select 1-5', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF8E8E93))),
              ],
            ),
            SizedBox(height: 12.h),
            FormField<List<String>>(
              initialValue: s.categories,
              validator: (val) {
                final v = val ?? [];
                if (v.isEmpty) return 'Select at least one category';
                if (v.length > 5) return 'Maximum 5 categories allowed';
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.w, runSpacing: 10.h,
                      children: korraVendorCategories.map((c) {
                        final isSelected = s.categories.contains(c);
                        return _CategoryChip(
                          label: c, isSelected: isSelected,
                          onTap: () {
                            final next = List<String>.from(s.categories);
                            if (isSelected) next.remove(c); else if (next.length < 5) next.add(c);
                            field.didChange(next);
                            _on(CategoryToggled(c));
                          },
                        );
                      }).toList(),
                    ),
                    if (field.hasError) Padding(padding: EdgeInsets.only(top: 8.h, left: 4.w), child: Text(field.errorText!, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.red, fontWeight: FontWeight.w500))),
                  ],
                );
              },
            ),

            SizedBox(height: 32.h),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: 32.h),

            // ----------------------------------------------------------
            // SECTION 2: LOCATION
            // ----------------------------------------------------------
            Text('Where do you sell?', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                children: [
                  Expanded(child: _PresenceTab(label: 'Online', value: Presence.online, group: s.presence, onTap: () => _on(PresenceChanged(Presence.online)))),
                  Expanded(child: _PresenceTab(label: 'Physical', value: Presence.physical, group: s.presence, onTap: () => _on(PresenceChanged(Presence.physical)))),
                  Expanded(child: _PresenceTab(label: 'Both', value: Presence.both, group: s.presence, onTap: () => _on(PresenceChanged(Presence.both)))),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: 32.h),

            // ----------------------------------------------------------
            // SECTION 3: SOCIAL PRESENCE (Gamified)
            // ----------------------------------------------------------
            Text('Digital Presence', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF111111))),
            SizedBox(height: 8.h),
            Text('Add at least 3 links to verify your business.', style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF666666))),
            SizedBox(height: 16.h),

            _RequirementProgress(count: _filledCount, required: 3),
            SizedBox(height: 24.h),

            // Social Inputs
            _SocialInput(controller: _instaCtl, focusNode: _instaFocus, label: 'Instagram', hint: 'username', icon: MdiIcons.instagram, brandColor: const Color(0xFFE1306C), prefixText: '@', validator: _validateLinks, onSubmitted: (_) => FocusScope.of(context).requestFocus(_twitterFocus)),
            SizedBox(height: 16.h),
            _SocialInput(controller: _twitterCtl, focusNode: _twitterFocus, label: 'Twitter / X', hint: 'username', icon: MdiIcons.twitter, brandColor: Colors.black, prefixText: '@', validator: _validateLinks, onSubmitted: (_) => FocusScope.of(context).requestFocus(_waFocus)),
            SizedBox(height: 16.h),
            _SocialInput(controller: _waCtl, focusNode: _waFocus, label: 'WhatsApp Group', hint: 'chat.whatsapp.com/...', icon: MdiIcons.whatsapp, brandColor: const Color(0xFF25D366), inputType: TextInputType.url, validator: _validateLinks, onSubmitted: (_) => FocusScope.of(context).requestFocus(_webFocus)),
            SizedBox(height: 16.h),
            _SocialInput(controller: _webCtl, focusNode: _webFocus, label: 'Website', hint: 'www.yourstore.com', icon: Iconsax.global, brandColor: Colors.blue.shade700, inputType: TextInputType.url, validator: _validateLinks, onSubmitted: (_) => FocusScope.of(context).requestFocus(_fbFocus)),
            SizedBox(height: 16.h),
            _SocialInput(controller: _fbCtl, focusNode: _fbFocus, label: 'Facebook', hint: 'facebook.com/page', icon: MdiIcons.facebook, brandColor: const Color(0xFF1877F2), inputType: TextInputType.url, validator: _validateLinks, onSubmitted: (_) => FocusScope.of(context).requestFocus(_tiktokFocus)),
            SizedBox(height: 16.h),
            _SocialInput(controller: _tiktokCtl, focusNode: _tiktokFocus, label: 'TikTok', hint: 'username', icon: Icons.tiktok, brandColor: Colors.black, prefixText: '@', validator: _validateLinks),
            SizedBox(height: 16.h),
             _SocialInput(controller: _otherCtl, focusNode: _otherFocus, label: 'Other (Linktree)', hint: 'https://...', icon: Iconsax.link_1, brandColor: Colors.grey.shade700, inputType: TextInputType.url, validator: _validateLinks),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

// 1. Progress Bar for Links
class _RequirementProgress extends StatelessWidget {
  final int count;
  final int required;

  const _RequirementProgress({required this.count, required this.required});

  @override
  Widget build(BuildContext context) {
    // Ensure progress is strictly between 0.0 and 1.0
    final progress = (count / required).clamp(0.0, 1.0);
    final isComplete = count >= required;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12.r),
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
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isComplete ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                ),
              ),
              if (isComplete)
                Icon(Iconsax.tick_circle, color: const Color(0xFF15803D), size: 18.sp),
            ],
          ),
          SizedBox(height: 8.h),
          
          // Progress Bar
          Stack(
            children: [
              // Background track
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
              // Animated Fill
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                // CHANGED: Use 'easeOut' to prevent negative overshooting
                curve: Curves.easeOutCubic, 
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

// 2. Premium Input (Shared Logic)
class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType inputType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PremiumInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<_PremiumInput> {
  bool _isFocused = false;
  @override
  void initState() { super.initState(); widget.focusNode.addListener(_handleFocus); }
  @override
  void dispose() { widget.focusNode.removeListener(_handleFocus); super.dispose(); }
  void _handleFocus() { setState(() => _isFocused = widget.focusNode.hasFocus); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
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
            textCapitalization: widget.textCapitalization,
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

// 3. Social Input (Variant of Premium Input)
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
  void initState() { super.initState(); widget.focusNode.addListener(_handleFocus); }
  @override
  void dispose() { widget.focusNode.removeListener(_handleFocus); super.dispose(); }
  void _handleFocus() { setState(() => _isFocused = widget.focusNode.hasFocus); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(widget.icon, size: 16.sp, color: widget.brandColor), SizedBox(width: 8.w), Text(widget.label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF111111)))]),
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
                height: 0.h,
                fontSize: 0.sp,
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

// ... Include _PresenceTab and _CategoryChip from previous code (omitted here to save space, they are unchanged)
class _PresenceTab extends StatelessWidget {
  final String label;
  final Presence value;
  final Presence group;
  final VoidCallback onTap;
  const _PresenceTab({required this.label, required this.value, required this.group, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isSelected = value == group;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(duration: const Duration(milliseconds:0), padding: EdgeInsets.symmetric(vertical: 10.h), alignment: Alignment.center, decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10.r), ), child: Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? const Color(0xFF111111) : const Color(0xFF8E8E93),),),),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () { HapticFeedback.selectionClick(); onTap(); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), decoration: BoxDecoration(color: isSelected ? KorraColors.brand : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isSelected ? KorraColors.brand : const Color(0xFFE5E5E5), width: 1, ), ), child: Text(label, style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF111111), ), ), ), );
  }
}