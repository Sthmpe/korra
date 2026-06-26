import 'package:flutter/material.dart';

class KorraColors {
  // -- Brand ------------------------------------------------------------
  static const brand      = Color(0xFFA54600);
  static const brandDark  = Color(0xFF7A3300); // pressed states
  static const brandLight = Color(0xFFFFF2EB); // brand-tinted backgrounds

  // -- Base -------------------------------------------------------------
  static const bg          = Colors.white;
  static const white       = Colors.white;
  static const black       = Color(0xFF1B1B1B);
  static const pureBlack   = Color(0xFF000000); // true black for shadow math
  static const transparent = Colors.transparent;

  // -- Surface / Background ---------------------------------------------
  static const surface     = Color(0xFFF9FAFB); // most common light surface
  static const warmSurface = Color(0xFFFAF7F4); // brand-tinted warm white
  static const ultraLight  = Color(0xFFFAFAFA); // near-white
  static const softWhite   = Color(0xFFF8F9FA); // soft grey-white

  // -- Text -------------------------------------------------------------
  static const text          = Colors.black87;
  static const textDark      = Color(0xFF101828); // near-black headings
  static const textSecondary = Color(0xFF8E8E93); // iOS-style grey
  static const textMuted     = Color(0xFF636366);
  static const textMid       = Color(0xFF667085); // mid grey body
  static const textLabel     = Color(0xFF344054); // dark grey labels / buttons
  static const textBody      = Color(0xFF475467); // grey body copy
  static const textHint      = Color(0xFF98A2B3); // placeholder / hint
  static const textSubtle    = Color(0xFF5E5E5E); // medium grey secondary
  static const textGrey      = Color(0xFF8B8B8B); // grey icons / captions
  static const nearBlack     = Color(0xFF111111); // near-black variant
  static const slate         = Color(0xFF64748B); // slate grey
  static const slateDeep     = Color(0xFF0F172A); // slate-900
  static const greyText      = Color(0xFF636366); // legacy alias - textMuted

  // -- Border -----------------------------------------------------------
  static const border         = Color(0xFFE0E0E0); // theme default border
  static const greyBorder     = Color(0xFFE5E5EA); // legacy iOS-style border
  static const surfaceBorder  = Color(0xFFF2F4F7); // card / divider border
  static const borderLight    = Color(0xFFEAECF0); // very light border
  static const warmBorder     = Color(0xFFEAE6E2); // warm grey border
  static const borderDisabled = Color(0xFFD0D5DD); // disabled state border

  // -- Input ------------------------------------------------------------
  static const inputFill = Color(0xFFF9F9F9);

  // -- Grey scale (Material equivalents) --------------------------------
  static const greyCancel   = Color(0xFF9E9E9E); // Colors.grey - dialog cancel
  static const greyShade100 = Color(0xFFF5F5F5);
  static const greyShade200 = Color(0xFFEEEEEE);
  static const greyShade300 = Color(0xFFE0E0E0); // = border
  static const greyShade400 = Color(0xFFBDBDBD);
  static const greyShade500 = Color(0xFF9E9E9E); // = greyCancel
  static const greyShade600 = Color(0xFF757575);
  static const greyShade700 = Color(0xFF616161);
  static const greyShade800 = Color(0xFF424242);
  static const greyShade900 = Color(0xFF212121);

  // -- Overlay ----------------------------------------------------------
  static const overlaySoft   = Color(0x0A000000); // ~4% black tint
  static const overlayLight  = Color(0x0F000000); // ~6% black tint
  static const overlayMedium = Color(0x29000000); // ~16% black tint
  static const overlayDark   = Color(0x99000000); // ~60% black scrim

  // -- Disabled ---------------------------------------------------------
  static const disabled   = Color(0xFFE4E7EC); // disabled container bg
  static const disabledFg = Color(0xFFD0D5DD); // disabled text / icon tint

  // -- Structural -------------------------------------------------------
  static const divider = Color(0xFFF2F4F7); // semantic alias for surfaceBorder
  static const shimmer = Color(0xFFE9EAEC); // skeleton / shimmer base

  // -- Semantic - Success -----------------------------------------------
  static const success          = Color(0xFF1DB954);
  static const successBg        = Color(0xFFECFDF5); // success-50 background
  static const successFg        = Color(0xFF027A48); // success-700 foreground
  static const settleGreen      = Color(0xFF059669); // settlement paid
  static const creditGreen      = Color(0xFF16A34A); // activity feed credit
  static const successIconLight = Color(0xFF6CE9A6); // light success icon

  // -- Semantic - Warning / Orange --------------------------------------
  static const warningBg        = Color(0xFFFFF7ED); // orange-50 background
  static const warningFg        = Color(0xFFB95000); // orange-700 foreground
  static const warningBorder    = Color(0xFFFFEDD5); // orange border
  static const warningIconLight = Color(0xFFFFDDB3); // light orange icon
  static const amberBg          = Color(0xFFFFFBEB); // amber-50 background
  static const amberFg          = Color(0xFFD97706); // amber-600 foreground
  static const receiptDebit     = Color(0xFFFF9800); // Colors.orange - debit

  // -- Semantic - Error / Red -------------------------------------------
  static const error        = Color(0xFFE53935); // legacy
  static const danger       = Color(0xFFE53935); // legacy alias
  static const errorBg      = Color(0xFFFEF3F2); // error-50 background
  static const errorFg      = Color(0xFFB42318); // error-700 foreground
  static const brightRed    = Color(0xFFD92D20); // vivid error red
  static const debtRed      = Color(0xFFDC2626); // debt / overdue
  static const deepRed      = Color(0xFFB3261E); // delete-account destructive
  static const dialogLogout = Color(0xFFF44336); // Colors.red - logout / delete

  // -- Semantic - Info / Blue -------------------------------------------
  static const infoBg       = Color(0xFFEFF8FF); // info-50 background
  static const infoFg       = Color(0xFF175CD3); // info-700 foreground
  static const infoChipBg   = Color(0xFFE3F2FD); // Colors.blue.shade50
  static const infoChipText = Color(0xFF1976D2); // Colors.blue.shade700

  // -- Semantic - Receipt -----------------------------------------------
  static const receiptCredit = Color(0xFF4CAF50); // Colors.green - credit

  // -- External services ------------------------------------------------
  static const whatsappGreen = Color(0xFF25D366);
  static const instagram     = Color(0xFFE1306C);
  static const facebook      = Color(0xFF1877F2);

  // -- Auth / Input tokens ----------------------------------------------
  static const surfaceCool        = Color(0xFFF2F2F7);
  static const labelGrey          = Color(0xFF666666);
  static const inputIconGrey      = Color(0xFF9CA3AF);
  static const inputPlaceholder   = Color(0xFFAAAAAA);
  static const inputBgInactive    = Color(0xFFF7F7F7);
  static const inputBorderInactive = Color(0xFFE5E5E5);
  static const dividerSubtle      = Color(0xFFF0F0F0);
  static const legalBorder        = Color(0xFFF3F4F6);
  static const borderCool         = Color(0xFFE5E7EB);
  static const textBodyCool       = Color(0xFF4B5563);
  static const iosBlack           = Color(0xFF1C1C1E);
  static const successText        = Color(0xFF15803D);
  static const warningText        = Color(0xFFC2410C);
  static const progressSuccessBg  = Color(0xFFF0FDF4);
  static const progressSuccessBorder = Color(0xFFBBF7D0);
  static const black54            = Color(0x8A000000);
  static const errorIconLight     = Color(0xFFE57373);
  static const readOnlyBg         = Color(0xFFF0F0F0);
}