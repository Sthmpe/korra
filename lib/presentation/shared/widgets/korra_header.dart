// lib/presentation/shared/widgets/korra_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/constants/colors.dart';
import '../../../../config/constants/sizes.dart';

class KorraHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackpressed;
  final bool showLeadingIcon;
  final bool showLogo;
  final List<Widget>? trailingActions;

  final VoidCallback? onHistory;
  final VoidCallback? onSupport;
  final bool showHistoryDot;

  // Search parameters
  final bool isSearchable;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClosed;
  final TextEditingController? searchController;

  const KorraHeader({
    super.key,
    required this.title,
    this.onBackpressed,
    this.showLeadingIcon = false,
    this.showLogo = false,
    this.trailingActions,
    this.onHistory,
    this.onSupport,
    this.showHistoryDot = false,
    this.isSearchable = false,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchClosed,
    this.searchController,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  State<KorraHeader> createState() => _KorraHeaderState();
}

class _KorraHeaderState extends State<KorraHeader> {
  bool _isSearching = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  void _onSearchTextChanged() {
    // Rebuild header when search text changes (e.g. to show/hide the clear button)
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w),
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 56.h,
          child: Row(
            children: [
              // --- 1. LEADING AREA ---
              if (_isSearching) ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                    if (widget.onSearchChanged != null) {
                      widget.onSearchChanged!('');
                    }
                    if (widget.onSearchClosed != null) {
                      widget.onSearchClosed!();
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: KorraSizes.iconLg.sp,
                    color: KorraColors.textDark,
                  ),
                ),
                SizedBox(width: 12.w),
              ] else if (widget.showLeadingIcon) ...[
                _BackButton(onPressed: widget.onBackpressed),
                SizedBox(width: 12.w),
              ] else if (widget.showLogo) ...[
                _BrandLogo(),
                SizedBox(width: 12.w),
              ],

              // --- 2. TITLE / SEARCH FIELD AREA ---
              Expanded(
                child: _isSearching
                    ? Container(
                        height: 36.h,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 16.sp,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: KorraColors.textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: widget.searchHint ?? 'Search...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(color: KorraColors.borderCool),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                onChanged: widget.onSearchChanged,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  if (widget.onSearchChanged != null) {
                                    widget.onSearchChanged!('');
                                  }
                                },
                                child: Icon(
                                  Icons.clear,
                                  size: 16.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      )
                    : (widget.showLogo
                        ? const SizedBox.shrink()
                        : Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              fontSize: KorraSizes.font2xl.sp,
                              fontWeight: KorraSizes.weightBold,
                              color: KorraColors.textDark,
                              letterSpacing: KorraSizes.trackingSnug,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
              ),

              // --- 3. ACTIONS AREA ---
              if (_isSearching)
                const SizedBox.shrink()
              else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildActionsList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionsList() {
    final List<Widget> actions = [];

    if (widget.isSearchable) {
      actions.add(
        _HeaderActionBtn(
          icon: Icons.search,
          onTap: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      );
    }

    if (widget.trailingActions != null) {
      actions.addAll(widget.trailingActions!);
    } else {
      if (widget.onHistory != null) {
        actions.add(_HeaderActionBtn(icon: Icons.history, onTap: widget.onHistory));
      }
      if (widget.onSupport != null) {
        if (actions.isNotEmpty) actions.add(SizedBox(width: 4.w));
        actions.add(
          _HeaderActionBtn(
            icon: Icons.notifications_none,
            onTap: widget.onSupport,
            showDot: widget.showHistoryDot,
          ),
        );
      }
    }

    return actions;
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
      child: Container(
        width: 40.w,
        height: 40.w,
        alignment: Alignment.centerLeft,
        child: Icon(
          Icons.arrow_back,
          size: KorraSizes.iconLg.sp,
          color: KorraColors.textDark,
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: KorraColors.brand,
        borderRadius: BorderRadius.circular(KorraSizes.chipRadius.r),
        boxShadow: [
          BoxShadow(
            color: KorraColors.brand.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(MdiIcons.crown, size: KorraSizes.iconMd.sp, color: Colors.white),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;

  const _HeaderActionBtn({
    required this.icon,
    this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          splashRadius: 24.r,
          constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
          icon: Icon(
            icon,
            size: KorraSizes.iconLg.sp,
            color: KorraColors.textDark,
          ),
        ),
        if (showDot)
          Positioned(
            right: 10.w,
            top: 10.h,
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
