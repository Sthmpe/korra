import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';
import 'sizes.dart';

class KorraDecorations {
  // -- Cards ------------------------------------------------------------

  // White card, 16r, surfaceBorder, subtle shadow - most common card
  static BoxDecoration get card => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
    border: Border.all(color: KorraColors.surfaceBorder),
    boxShadow: [
      BoxShadow(
        color: KorraColors.textDark.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // White card, 12r, surfaceBorder - compact list item card
  static BoxDecoration get cardSm => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
    border: Border.all(color: KorraColors.surfaceBorder),
  );

  // White card, 16r, no border - used inside container with own bg
  static BoxDecoration get cardFlat => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
  );

  // White card with light border + soft elevation - plan/status cards
  static BoxDecoration get cardElevated => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.circular(KorraSizes.cardRadius.r),
    border: Border.all(color: KorraColors.borderLight),
    boxShadow: [
      BoxShadow(
        color: KorraColors.pureBlack.withOpacity(0.06),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // -- Sheets -----------------------------------------------------------

  // White, top 24r, shadow - standard bottom sheet
  static BoxDecoration get sheet => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(KorraSizes.sheetRadius.r),
    ),
    boxShadow: [
      BoxShadow(
        color: KorraColors.pureBlack.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  );

  // -- Snackbar ---------------------------------------------------------

  // White, 20r, diffuse shadow - floating notification card
  static BoxDecoration get snackbar => BoxDecoration(
    color: KorraColors.white,
    borderRadius: BorderRadius.circular(KorraSizes.s20.r),
    boxShadow: [
      BoxShadow(
        color: KorraColors.pureBlack.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ],
  );

  // -- Gradient cards ---------------------------------------------------

  // Brand gradient, 24r, brand shadow - vault/balance hero card
  static BoxDecoration get brandGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8B3A00),
        KorraColors.brand,
        const Color(0xFF5C2600),
      ],
    ),
    borderRadius: BorderRadius.circular(KorraSizes.sheetRadius.r),
    boxShadow: [
      BoxShadow(
        color: KorraColors.brand.withOpacity(0.4),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // Two-tone brand gradient - customer wallet card
  static BoxDecoration get brandGradientLight => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [KorraColors.brand, KorraColors.brandDark],
    ),
    borderRadius: BorderRadius.circular(KorraSizes.sheetRadius.r),
    boxShadow: [
      BoxShadow(
        color: KorraColors.brand.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // -- Vault / warm surface ---------------------------------------------

  // Warm surface, 24r, warm border, subtle brand shadow - hold vault
  static BoxDecoration get holdVault => BoxDecoration(
    color: KorraColors.warmSurface,
    borderRadius: BorderRadius.circular(KorraSizes.sheetRadius.r),
    border: Border.all(
      color: KorraColors.brandDark.withOpacity(0.06),
    ),
    boxShadow: [
      BoxShadow(
        color: KorraColors.brand.withOpacity(0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // -- Image containers -------------------------------------------------

  // Surface bg, 12r, surfaceBorder - image/product thumbnail placeholder
  static BoxDecoration get imagePlaceholder => BoxDecoration(
    color: KorraColors.surface,
    borderRadius: BorderRadius.circular(KorraSizes.fieldRadius.r),
    border: Border.all(color: KorraColors.surfaceBorder),
  );

  // Surface bg, 6r, borderLight - small avatar / initials box
  static BoxDecoration get avatarBox => BoxDecoration(
    color: KorraColors.surface,
    borderRadius: BorderRadius.circular(KorraSizes.s6.r),
    border: Border.all(color: KorraColors.borderLight),
  );

  // -- UI elements ------------------------------------------------------

  // Sheet drag handle pill - 40w x 4h, greyShade300
  static BoxDecoration get handleBar => BoxDecoration(
    color: KorraColors.border,
    borderRadius: BorderRadius.circular(KorraSizes.pillRadius.r),
  );

  // Nav active indicator bar - brand, top-rounded
  static BoxDecoration get navIndicator => BoxDecoration(
    color: KorraColors.brand,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    boxShadow: [
      BoxShadow(
        color: KorraColors.brand.withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ],
  );

  // Count badge - brand bg, rounded
  static BoxDecoration get countBadge => BoxDecoration(
    color: KorraColors.brand,
    borderRadius: BorderRadius.circular(KorraSizes.chipRadius.r),
    border: Border.all(color: KorraColors.white, width: 1.5),
  );

  // -- Parameterized decorations ----------------------------------------

  // Status badge with dynamic background - reservation / plan status chips
  static BoxDecoration statusBadge(Color bg) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(KorraSizes.s20.r),
    border: Border.all(color: bg.withOpacity(0.5)),
  );

  // Pill status badge - product approval status
  static BoxDecoration pillBadge(Color bg) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(KorraSizes.pillRadius.r),
    border: Border.all(color: bg.withOpacity(0.25)),
  );

  // Circular icon container - takes a background color
  static BoxDecoration iconCircle(Color bg) => BoxDecoration(
    color: bg,
    shape: BoxShape.circle,
  );

  // Solid color rounded container - KPI bg, calendar highlight, etc.
  static BoxDecoration coloredRounded(Color bg, {double? radius}) =>
      BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          (radius ?? KorraSizes.cardRadius).r,
        ),
      );
}