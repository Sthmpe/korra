import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// All GoogleFonts getters evaluate .sp at widget build time (requires ScreenUtil.init).
/// Styles with no baked-in color: supply via .copyWith(color: KorraColors.xxx).
class KorraTextStyles {
  // -- Legacy (preserved) -----------------------------------------------
  static const boldDefault  = TextStyle(fontWeight: FontWeight.bold);
  static const brandBold    = TextStyle(color: KorraColors.brand, fontWeight: FontWeight.w700);
  static const dialogCancel = TextStyle(color: KorraColors.greyCancel);
  static const dialogLogout = TextStyle(color: KorraColors.dialogLogout);
  static const dialogDelete = TextStyle(color: KorraColors.dialogLogout);

  // -- Display - hero monetary amounts ----------------------------------
  // 34sp w800 tabular - vault balance card (color via .copyWith)
  static TextStyle get displayLg => GoogleFonts.inter(
    fontSize: 34.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // 32sp w800 tabular - hold vault hero amount (color via .copyWith)
  static TextStyle get displayMd => GoogleFonts.inter(
    fontSize: 32.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // 32sp w900 tabular - store balance page total
  static TextStyle get displayBalance => GoogleFonts.inter(
    fontSize: 32.sp,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: KorraColors.slateDeep,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // -- Heading ----------------------------------------------------------
  // 24sp w800 - KPI block stat numbers
  static TextStyle get headingXl => GoogleFonts.inter(
    fontSize: 24.sp,
    fontWeight: FontWeight.w800,
    color: KorraColors.textDark,
    height: 1.0,
  );

  // 20sp w700 - app bar title / modal header
  static TextStyle get headingMd => GoogleFonts.inter(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.nearBlack,
    letterSpacing: -0.5,
  );

  // 18sp w700 - section header
  static TextStyle get headingSm => GoogleFonts.inter(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.black,
    letterSpacing: -0.5,
  );

  // -- Title ------------------------------------------------------------
  // 16sp w700 - sheet section / tile heading
  static TextStyle get titleLg => GoogleFonts.inter(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.textDark,
  );

  // 16sp w700 tabular - pending amount in balance card (color via .copyWith)
  static TextStyle get titleLgTabular => GoogleFonts.inter(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // 14sp w700 - tile product title / list row heading
  static TextStyle get titleMd => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.text,
  );

  // 14sp w800 - monetary amount in list rows
  static TextStyle get titleMdBold => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w800,
    color: KorraColors.text,
  );

  // 14sp w600 - customer name / secondary list title
  static TextStyle get titleMdMedium => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: KorraColors.textDark,
  );

  // -- Body -------------------------------------------------------------
  // 15sp h1.5 - modal / sheet descriptive copy
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 15.sp,
    height: 1.5,
    color: KorraColors.textMuted,
  );

  // 14sp w500 - form input / standard list body
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: KorraColors.textDark,
  );

  // 14sp w500 - empty state / subtle hint body
  static TextStyle get bodyMdSubtle => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: KorraColors.greyCancel,
  );

  // 13sp w500 - KPI tile label / secondary body
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    color: KorraColors.greyShade500,
  );

  // -- Label ------------------------------------------------------------
  // 13.5sp w600 h1.4 - snackbar message text
  static TextStyle get snackbarText => GoogleFonts.inter(
    fontSize: 13.5.sp,
    fontWeight: FontWeight.w600,
    color: KorraColors.textDark,
    height: 1.4,
  );

  // 13sp w600 - action link / "View All" text
  static TextStyle get labelLg => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: KorraColors.brand,
  );

  // 13sp w600 tracked - status chip / ID prefix label
  static TextStyle get labelLgMuted => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: KorraColors.textMuted,
    letterSpacing: 0.5,
  );

  // 13sp w700 - inline card button ("Withdraw")
  static TextStyle get labelLgBold => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.brand,
  );

  // 13sp w600 - slate section sub-label
  static TextStyle get labelLgSlate => GoogleFonts.inter(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: KorraColors.slate,
  );

  // 12sp w700 tracked wide - uppercase section header (color via .copyWith)
  static TextStyle get labelMdUpper => GoogleFonts.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  // 12sp w700 - badge inline label
  static TextStyle get labelMdBold => GoogleFonts.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.brand,
  );

  // 12sp h1.4 - RichText context line base (color via .copyWith)
  static TextStyle get labelMd => GoogleFonts.inter(
    fontSize: 12.sp,
    height: 1.4,
    color: KorraColors.textMuted,
  );

  // -- Caption ----------------------------------------------------------
  // 11sp - timestamp / "of total" secondary text
  static TextStyle get captionLg => GoogleFonts.inter(
    fontSize: 11.sp,
    color: KorraColors.textMuted,
  );

  // 11sp w600 tracked - column header / progress % label
  static TextStyle get captionLgMedium => GoogleFonts.inter(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: KorraColors.textHint,
  );

  // 11sp w600/w500 - bottom nav label (active/inactive)
  static TextStyle navLabel({required bool selected}) => GoogleFonts.inter(
    fontSize: 11.sp,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    color: selected ? KorraColors.brand : KorraColors.greyCancel,
    letterSpacing: -0.2,
  );

  // 10sp w600 tracked - reservation ID / status badge (color via .copyWith)
  static TextStyle get captionMd => GoogleFonts.inter(
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: KorraColors.textMuted,
  );

  // 9sp w800 - calendar month / nav badge counter (color via .copyWith)
  static TextStyle get captionSm => GoogleFonts.inter(
    fontSize: 9.sp,
    fontWeight: FontWeight.w800,
  );

  // 9sp w700 white - notification badge counter
  static TextStyle get captionSmBadge => GoogleFonts.inter(
    fontSize: 9.sp,
    fontWeight: FontWeight.w700,
    color: KorraColors.white,
  );

  // 8sp w600 tracked - micro uppercase label (PENDING SETTLEMENT)
  static TextStyle get micro => GoogleFonts.inter(
    fontSize: 8.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}
