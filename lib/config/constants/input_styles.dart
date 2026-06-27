import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';
import 'sizes.dart';
import 'text_styles.dart';

/// Text field styles, container decorations, and InputDecoration factories.
///
/// Two rendering patterns exist in the codebase:
///
/// WRAPPED - AnimatedContainer handles focus state visually.
/// Use [containerPremium] or [containerStandard] on the wrapper, then
/// [premiumDecoration] or [standardDecoration] inside the TextFormField.
/// All inner borders are transparent so the container shows through.
///
/// STANDALONE - TextFormField owns its own border and fill.
/// Use [filledDecoration], [productFormDecoration], [searchDecoration], etc.
class KorraInputStyles {

  // -------------------------------------------------------------------------
  // TEXT STYLES
  // -------------------------------------------------------------------------

  /// 15sp w600 black - standard input text for all wrapped fields.
  static TextStyle get inputText => KorraTextStyles.inter(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    color: KorraColors.black,
  );

  /// 14sp w500 black - profile / change-password standalone fields.
  static TextStyle get inputTextMd => KorraTextStyles.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  /// 20sp w700 textDark tracked - payout amount field.
  static TextStyle get inputTextAmount => KorraTextStyles.inter(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.textDark,
    letterSpacing: 0.5,
  );

  /// 36sp w800 h1 black - large currency amount display (create plan).
  static TextStyle get inputTextAmountLg => KorraTextStyles.inter(
    fontSize: 36.sp,
    fontWeight: FontWeight.w800,
    color: KorraColors.black,
    height: 1.0,
  );

  /// 14sp w500 cool-grey - hint for premium/link wrapped fields.
  static TextStyle get hintPremium => KorraTextStyles.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF9CA3AF),
  );

  /// 14sp w400 softer-grey - hint for standard signup/KYC wrapped fields.
  static TextStyle get hintStandard => KorraTextStyles.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFAAAAAA),
  );

  /// No fixed size, greyShade400 - hint for standalone filled fields.
  static TextStyle get hintFilled => KorraTextStyles.inter(
    color: KorraColors.greyShade400,
  );

  /// 14sp greyShade400 - hint for most search fields.
  static TextStyle get hintSearch => KorraTextStyles.inter(
    fontSize: 14.sp,
    color: KorraColors.greyShade400,
  );

  /// borderDisabled color, no fixed size - hint for amount/currency fields.
  static TextStyle get hintAmount => KorraTextStyles.inter(
    color: KorraColors.borderDisabled,
  );

  /// 12sp w500 red - standard error text for profile/password fields.
  static TextStyle get errorText => KorraTextStyles.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: Colors.red,
  );

  /// 12sp w500 red.shade600 - error text for the login premium field.
  static TextStyle get errorTextStrong => KorraTextStyles.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: Colors.red.shade600,
  );

  /// 10sp brightRed - compact error text for product form fields.
  static TextStyle get errorTextSm => KorraTextStyles.inter(
    fontSize: 10.sp,
    color: KorraColors.brightRed,
  );

  /// 13.5sp grey - floating label style for label-type inputs.
  static TextStyle get labelStyle => KorraTextStyles.inter(
    fontSize: 13.5.sp,
    color: Colors.grey,
  );

  // -------------------------------------------------------------------------
  // ANIMATED CONTAINER DECORATIONS - WRAPPED INPUTS
  // -------------------------------------------------------------------------

  /// BoxDecoration for the 16r (cardRadius) AnimatedContainer wrapper.
  /// Used by login and link-input fields.
  static BoxDecoration containerPremium({required bool isFocused}) =>
      BoxDecoration(
        color: isFocused ? KorraColors.white : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
        border: Border.all(
          color: isFocused ? KorraColors.brand : KorraColors.transparent,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: KorraColors.brand.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      );

  /// BoxDecoration for the 12r (fieldRadius) AnimatedContainer wrapper.
  /// Used by signup steps and KYC fields.
  /// [showShadow] - pass false for KYC sheets (signup steps use true).
  static BoxDecoration containerStandard({
    required bool isFocused,
    bool readOnly = false,
    bool showShadow = true,
  }) =>
      BoxDecoration(
        color: readOnly
            ? const Color(0xFFF0F0F0)
            : (isFocused ? KorraColors.white : const Color(0xFFF7F7F7)),
        borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
        border: Border.all(
          color: isFocused && !readOnly
              ? KorraColors.brand
              : const Color(0xFFE5E5E5),
        ),
        boxShadow: isFocused && !readOnly && showShadow
            ? [
                BoxShadow(
                  color: KorraColors.brand.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      );

  /// BoxDecoration for a field that always shows the brand border regardless
  /// of focus. Used by the KYC phone-number input.
  static BoxDecoration containerBrandBorder() => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
    border: Border.all(color: KorraColors.brand),
  );

  // -------------------------------------------------------------------------
  // INPUTDECORATION - WRAPPED (transparent borders, container owns state)
  // -------------------------------------------------------------------------

  /// InputDecoration for 16r premium wrapped inputs (login, link-input).
  /// All 5 border states are transparent - [containerPremium] owns the border.
  static InputDecoration premiumDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: hintPremium,
        prefixIcon: prefixIcon,
        prefixIconConstraints: BoxConstraints(minWidth: KorraSizes.s48.w),
        suffixIcon: suffixIcon,
        border: _transparentBorder(KorraSizes.cardRadius),
        enabledBorder: _transparentBorder(KorraSizes.cardRadius),
        focusedBorder: _transparentBorder(KorraSizes.cardRadius),
        errorBorder: _transparentBorder(KorraSizes.cardRadius),
        focusedErrorBorder: _transparentBorder(KorraSizes.cardRadius),
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s16.w,
          vertical: KorraSizes.s14.h,
        ),
        errorStyle: errorTextStrong,
      );

  /// InputDecoration for 12r standard wrapped inputs (signup steps, KYC).
  /// All 5 border states are transparent - [containerStandard] owns the border.
  static InputDecoration standardDecoration({
    required String hint,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: hintStandard,
        suffixIcon: suffixIcon,
        border: _transparentBorder(KorraSizes.fieldRadius),
        enabledBorder: _transparentBorder(KorraSizes.fieldRadius),
        focusedBorder: _transparentBorder(KorraSizes.fieldRadius),
        errorBorder: _transparentBorder(KorraSizes.fieldRadius),
        focusedErrorBorder: _transparentBorder(KorraSizes.fieldRadius),
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s16.w,
          vertical: KorraSizes.s14.h,
        ),
        errorStyle: errorText,
      );

  // -------------------------------------------------------------------------
  // INPUTDECORATION - STANDALONE FIELDS
  // -------------------------------------------------------------------------

  /// Profile / change-password fields.
  /// Filled, grey outline, brand focus. Default fill is [KorraColors.surface]
  /// (0xFFF9FAFB) - pass [KorraColors.white] for white variants.
  static InputDecoration filledDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = KorraColors.surface,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: hintFilled,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s16.w,
          vertical: KorraSizes.s14.h,
        ),
        errorStyle: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(
            color: KorraColors.greyShade300.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(
            color: KorraColors.greyShade300.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      );

  /// Product add / edit form fields.
  /// Filled, EAECF0 outline, brand focus. Supports disabled state.
  static InputDecoration productFormDecoration({
    required String hint,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
    bool enabled = true,
  }) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? KorraColors.surface : KorraColors.surfaceBorder,
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s16.w,
          vertical: KorraSizes.s14.h,
        ),
        errorStyle: errorTextSm,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: KorraColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: KorraColors.borderLight),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
        ),
      );

  /// Search fields with fill. No visible border by default; brand on focus.
  /// Pass [borderColor] for outlined variants (help center uses
  /// [KorraColors.greyShade300] at 50%, category search uses
  /// [KorraColors.borderLight]).
  /// Pass [radius] for non-standard corners (help center uses 10r).
  static InputDecoration searchDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = KorraColors.surface,
    Color borderColor = Colors.transparent,
    double radius = KorraSizes.fieldRadius,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: hintSearch,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s16.w,
          vertical: KorraSizes.s12.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.r),
          borderSide: const BorderSide(color: KorraColors.brand),
        ),
      );

  /// Naked search inside a styled container - no fill, no border.
  /// Used by reservation_search_bar which draws its own container.
  static InputDecoration searchNakedDecoration({required String hint}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: KorraTextStyles.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: KorraColors.textHint,
        ),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s12.w,
          vertical: KorraSizes.s14.h,
        ),
      );

  /// Borderless inline amount input (create-plan large currency field).
  /// No fill, InputBorder.none, minimal padding.
  static InputDecoration amountDecoration({
    required String hint,
    Widget? prefixIcon,
    BoxConstraints prefixIconConstraints =
        const BoxConstraints(minWidth: 0, minHeight: 0),
  }) =>
      InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s8.w,
          vertical: KorraSizes.s8.h,
        ),
        hintText: hint,
        hintStyle: hintAmount,
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
      );

  /// Payout amount field - white fill, visible border, currency prefix.
  /// [hasError] switches borders to muted grey to signal an error state.
  static InputDecoration payoutAmountDecoration({
    bool hasError = false,
    String currencySymbol = '₦',
  }) =>
      InputDecoration(
        hintText: '0.00',
        hintStyle: hintAmount,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: KorraSizes.s16.w,
            right: KorraSizes.s8.w,
          ),
          child: Text(
            currencySymbol,
            style: KorraTextStyles.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: KorraColors.textMid,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: KorraColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(
            color: hasError ? KorraColors.textMid : KorraColors.borderDisabled,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(
            color: hasError ? KorraColors.textMid : KorraColors.borderDisabled,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(
            color: hasError ? KorraColors.textMid : KorraColors.brand,
            width: 1.5,
          ),
        ),
      );

  /// Label-type fields that use labelText instead of hintText.
  /// Filled white, grey.shade300 outline, brand focus.
  /// Used by password-verification sheet. Pass [errorText] to show inline error.
  static InputDecoration labelDecoration({
    required String label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
        errorStyle: KorraTextStyles.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: KorraColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: KorraSizes.s16.w,
          vertical: KorraSizes.s16.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(color: KorraColors.greyShade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: BorderSide(color: KorraColors.greyShade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.5),
        ),
      );

  // -------------------------------------------------------------------------
  // THEME OVERRIDE
  // -------------------------------------------------------------------------

  /// InputDecorationTheme for SearchDelegate (plan search screen).
  static InputDecorationTheme searchDelegateTheme() => InputDecorationTheme(
    border: InputBorder.none,
    hintStyle: KorraTextStyles.inter(
      fontSize: 16.sp,
      color: KorraColors.greyShade400,
    ),
  );

  // -------------------------------------------------------------------------
  // PRIVATE HELPERS
  // -------------------------------------------------------------------------

  static OutlineInputBorder _transparentBorder(double radius) =>
      OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(radius.r),
      );
}
