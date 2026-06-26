import 'package:flutter/material.dart';

/// Design tokens for all snackbar variants.
///
/// Two snackbar styles exist in the codebase:
/// - Floating pill (showAppSnackbar) - rounded card, white bg, icon pill
/// - Accent bar (showSuccessSnackbar) - card with brand left border accent
class KorraSnackbars {
  // -- Durations -------------------------------------------------------
  static const Duration durationShort  = Duration(seconds: 2); // accent bar
  static const Duration durationNormal = Duration(seconds: 4); // floating pill

  // -- Animation -------------------------------------------------------
  static const Duration animationDuration = Duration(milliseconds: 400);

  // -- Layout ----------------------------------------------------------
  static const double marginH          = 16.0;  // horizontal margin, apply .w
  static const double marginV          = 12.0;  // vertical margin (accent bar only), apply .h
  static const double paddingH         = 16.0;  // apply .w
  static const double paddingVPill     = 16.0;  // floating pill, apply .h
  static const double paddingVAccent   = 12.0;  // accent bar, apply .h
  static const double maxWidthAccent   = 340.0; // max width for accent bar

  // -- Shape -----------------------------------------------------------
  static const double radiusPill   = 20.0; // floating pill - apply .r
  static const double radiusAccent = 12.0; // accent bar - apply .r

  // -- Shadow (floating pill) ------------------------------------------
  static const Color  shadowColor      = Color(0x14000000); // black @ 8% opacity
  static const double shadowBlurPill   = 24.0;
  static const double shadowBlurAccent = 12.0;
  static const Offset shadowOffsetPill   = Offset(0, 8);
  static const Offset shadowOffsetAccent = Offset(0, 6);

  // -- Accent bar left border ------------------------------------------
  static const double accentBorderWidth = 4.0;
  // color = KorraColors.brand (referenced at usage site)

  // -- Icon container (floating pill) ----------------------------------
  static const double iconContainerSize = 36.0; // apply .w

  // -- Icon sizes ------------------------------------------------------
  static const double iconSize  = 20.0;  // apply .sp
  static const double closeSize = 20.0;  // apply .sp

  // -- Message text ----------------------------------------------------
  static const double messageFontSizePill   = 13.5; // apply .sp
  static const double messageFontSizeAccent = 14.0; // apply .sp
  static const FontWeight messageFontWeight = FontWeight.w600;
  static const double messageLineHeightPill   = 1.4;
  static const double messageLineHeightAccent = 1.3;
  static const Color  messageColor = Color(0xFF1F2937); // grey-900

  // -- Type palette (floating pill) ------------------------------------
  // success
  static const Color successPrimary = Color(0xFF10B981); // emerald-500
  static const Color successBg      = Color(0xFFECFDF5); // emerald-50

  // warning
  static const Color warningPrimary = Color(0xFFF59E0B); // amber-400
  static const Color warningBg      = Color(0xFFFFFBEB); // amber-50

  // error
  static const Color errorPrimary = Color(0xFFEF4444); // red-500
  static const Color errorBg      = Color(0xFFFEF2F2); // red-50

  // info
  static const Color infoPrimary = Color(0xFF3B82F6); // blue-500
  static const Color infoBg      = Color(0xFFEFF6FF); // blue-50
}
