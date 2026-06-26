import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'sizes.dart';

/// Named BorderRadius and RoundedRectangleBorder shapes for the Korra design system.
///
/// All getters use ScreenUtil extensions (.r) - call after ScreenUtil.init().
///
/// BorderRadius getters: use in BoxDecoration.borderRadius, ClipRRect,
/// InkWell.borderRadius.
/// RoundedRectangleBorder getters: use in shape: on buttons, dialogs, sheets.
class KorraShapes {

  // -------------------------------------------------------------------------
  // BORDER RADIUS - SYMMETRIC
  // -------------------------------------------------------------------------

  /// 4r - progress bar clips, tiny badge corners.
  static BorderRadius get xxs => BorderRadius.circular(KorraSizes.s4.r);

  /// 8r - small UI elements.
  static BorderRadius get xs => BorderRadius.circular(KorraSizes.s8.r);

  /// 10r - filter chips, chip buttons.
  static BorderRadius get chip => BorderRadius.circular(KorraSizes.chipRadius.r);

  /// 11r - reservation tile product image. Intentionally 1dp less than field.
  static BorderRadius get imageTileSm => BorderRadius.circular(11.r);

  /// 12r - input fields, secondary buttons, list-item cards. Most common.
  static BorderRadius get field => BorderRadius.circular(KorraSizes.fieldRadius.r);

  /// 14r - medium CTA buttons (product, payment, signup step actions).
  static BorderRadius get buttonMid => BorderRadius.circular(KorraSizes.s14.r);

  /// 16r - primary buttons, card containers.
  static BorderRadius get card => BorderRadius.circular(KorraSizes.cardRadius.r);

  /// 18r - login header image clip (inner clip inside a 20r container).
  static BorderRadius get loginImage => BorderRadius.circular(18.r);

  /// 20r - product detail hero images, InkWell bottom ripple areas.
  static BorderRadius get lg => BorderRadius.circular(KorraSizes.s20.r);

  /// 24r - large containers, sheet body clips, product share card.
  static BorderRadius get sheet => BorderRadius.circular(KorraSizes.sheetRadius.r);

  /// 32r - large hero clips (limit upgrade screen, transaction PIN sheet).
  static BorderRadius get xl => BorderRadius.circular(KorraSizes.s32.r);

  /// Full pill - progress indicators, pill badges.
  static BorderRadius get pill => BorderRadius.circular(KorraSizes.pillRadius.r);

  // -------------------------------------------------------------------------
  // BORDER RADIUS - ASYMMETRIC
  // -------------------------------------------------------------------------

  /// Top 24r, bottom straight - standard bottom sheet container.
  /// Used in 20+ showModalBottomSheet calls across the codebase.
  static BorderRadius get sheetTop =>
      BorderRadius.vertical(top: Radius.circular(KorraSizes.sheetRadius.r));

  /// Top 20r, bottom straight - plan details nested sub-sheet.
  static BorderRadius get sheetTopMd =>
      BorderRadius.vertical(top: Radius.circular(KorraSizes.s20.r));

  /// Top 16r, bottom straight - compact top-rounded container.
  static BorderRadius get sheetTopSm =>
      BorderRadius.vertical(top: Radius.circular(KorraSizes.cardRadius.r));

  /// Top 32r, bottom straight - large hero modal (transaction PIN, limit upgrade).
  static BorderRadius get sheetTopLg =>
      BorderRadius.vertical(top: Radius.circular(KorraSizes.s32.r));

  /// Bottom 16r, top straight - bottom-capped container (receipt card footer).
  static BorderRadius get bottomCap =>
      BorderRadius.vertical(bottom: Radius.circular(KorraSizes.cardRadius.r));

  /// Bottom 20r, top straight - InkWell ripple at the base of a card.
  /// Used in product_edit_screen, Add_product_page, payout_screen_ui.
  static BorderRadius get bottomInkWell => BorderRadius.only(
        bottomLeft: Radius.circular(KorraSizes.s20.r),
        bottomRight: Radius.circular(KorraSizes.s20.r),
      );

  /// Right side 10r only - left half of a horizontal split card (product share).
  static BorderRadius get rightRounded =>
      BorderRadius.horizontal(right: Radius.circular(KorraSizes.chipRadius.r));

  /// Left side 10r only - right half of a horizontal split card (product share).
  static BorderRadius get leftRounded =>
      BorderRadius.horizontal(left: Radius.circular(KorraSizes.chipRadius.r));

  // -------------------------------------------------------------------------
  // ROUNDED RECTANGLE BORDERS (for shape: on buttons, dialogs, sheets)
  // -------------------------------------------------------------------------

  /// 10r - small filter/action chip buttons.
  static RoundedRectangleBorder get chipButton =>
      RoundedRectangleBorder(borderRadius: chip);

  /// 12r - most secondary and inline card buttons.
  static RoundedRectangleBorder get buttonSm =>
      RoundedRectangleBorder(borderRadius: field);

  /// 14r - medium CTA buttons (product, payment actions, signup steps).
  static RoundedRectangleBorder get buttonMd =>
      RoundedRectangleBorder(borderRadius: buttonMid);

  /// 16r - primary large CTA and main flow buttons.
  static RoundedRectangleBorder get buttonLg =>
      RoundedRectangleBorder(borderRadius: card);

  /// 16r - standard alert / confirmation dialog.
  static RoundedRectangleBorder get dialog =>
      RoundedRectangleBorder(borderRadius: card);

  /// 24r - large dialog (reservation detail, deletion confirm).
  static RoundedRectangleBorder get dialogLg =>
      RoundedRectangleBorder(borderRadius: sheet);

  /// Top 24r - standard showModalBottomSheet shape. Used in 20+ locations.
  static RoundedRectangleBorder get sheetShape =>
      RoundedRectangleBorder(borderRadius: sheetTop);

  /// Top 20r - sub-sheet / plan details nested sheet.
  static RoundedRectangleBorder get sheetShapeMd =>
      RoundedRectangleBorder(borderRadius: sheetTopMd);
}
