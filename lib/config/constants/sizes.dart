import 'package:flutter/material.dart';

/// Raw numeric constants. Apply screenutil extensions in widgets (.r / .h / .w / .sp).
class KorraSizes {
  // -- Radius -----------------------------------------------------------
  static const xs           =  4.0; // tiny badge / pill corner
  static const sm           =  8.0; // small chip / tag
  static const chipRadius   = 10.0; // filter chips
  static const fieldRadius  = 12.0; // input fields
  static const cardRadius   = 16.0; // cards
  static const sheetRadius  = 24.0; // bottom sheets
  static const segmentRadius = 14.0; // segment control outer bg
  static const logoRadius   = 18.0; // logo / avatar corner
  static const pillRadius   = 999.0; // fully rounded pill button / badge

  // -- Spacing scale (raw numbers for padding and Gaps) -----------------
  static const s2  =  2.0;
  static const s4  =  4.0;
  static const s5  =  5.0;
  static const s6  =  6.0;
  static const s7  =  7.0;
  static const s8  =  8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s28 = 28.0;
  static const s32 = 32.0;
  static const s35 = 35.0;
  static const s36 = 36.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s56 = 56.0;
  static const s64 = 64.0;

  // -- Icon sizes (use with .r or .sp) ----------------------------------
  static const iconXs  = 12.0;
  static const iconSm  = 16.0;
  static const iconMd  = 20.0; // default icon size
  static const iconLg  = 24.0;
  static const icon28  = 28.0;
  static const iconXl  = 32.0;
  static const icon2xl = 40.0;
  static const icon3xl = 48.0;

  // -- Components -------------------------------------------------------
  static const buttonHeight   = 54.0; // primary button
  static const buttonHeightSm = 36.0; // compact / secondary button
  static const inputHeight    = 52.0; // text field
  static const chipHeight     = 32.0; // filter / status chip
  static const avatarSm       = 36.0; // small avatar / icon container
  static const avatarMd       = 54.0; // product / receipt image
  static const avatarLg       = 80.0; // large logo / profile image

  // -- Layout -----------------------------------------------------------
  static const gutter       = 20.0; // horizontal page margin
  static const gutterSm     = 16.0; // tight horizontal margin
  static const navBarHeight = 72.0; // bottom navigation bar

  // -- Font sizes (apply .sp in widgets) --------------------------------
  static const double fontMicro    =  8.0;  // tiny badge label
  static const double font2xs      =  9.0;
  static const double fontXxs      = 10.0;
  static const double fontXs       = 11.0;
  static const double fontXsHalf   = 11.5;
  static const double fontSm       = 12.0;
  static const double fontSmHalf   = 12.5;
  static const double fontSmPlus   = 13.0;
  static const double fontSmPlusH  = 13.5;  // 13.5 - half step
  static const double fontMd       = 14.0;
  static const double fontMdHalf   = 14.5;
  static const double fontMdPlus   = 15.0;
  static const double fontLg       = 16.0;  // body large / button label
  static const double fontXl       = 18.0;  // heading small
  static const double font2xl      = 20.0;  // heading medium
  static const double font2xlPlus  = 22.0;
  static const double font3xl      = 24.0;  // heading large
  static const double font3xlPlus  = 26.0;
  static const double font4xl      = 28.0;
  static const double font4xlPlus  = 30.0;
  static const double font5xl      = 32.0;  // display small
  static const double font5xlPlus  = 34.0;
  static const double font6xl      = 36.0;  // display medium
  static const double font7xl      = 48.0;
  static const double font8xl      = 56.0;
  static const double fontDisplay1 = 160.0; // decorative/hero
  static const double fontDisplay2 = 200.0; // decorative/hero

  // -- Font weights -----------------------------------------------------
  static const FontWeight weightRegular   = FontWeight.w400;
  static const FontWeight weightMedium    = FontWeight.w500;
  static const FontWeight weightSemiBold  = FontWeight.w600;
  static const FontWeight weightBold      = FontWeight.w700;
  static const FontWeight weightExtraBold = FontWeight.w800;
  static const FontWeight weightBlack     = FontWeight.w900;

  // -- Line heights (TextStyle height multiplier) -----------------------
  static const double lineHeightTight   = 1.2;
  static const double lineHeightSnug    = 1.3;
  static const double lineHeightMd      = 1.4;
  static const double lineHeightNormal  = 1.5;
  static const double lineHeightRelaxed = 1.6;

  // -- Letter spacing (apply directly - already in logical pixels) ------
  static const double trackingTightest = -1.5;
  static const double trackingTighter  = -1.0;
  static const double trackingTight    = -0.8;
  static const double trackingSnug     = -0.5;
  static const double trackingMinus3   = -0.3;
  static const double trackingMinus2   = -0.2;
  static const double trackingWide     =  0.5;
  static const double trackingWider    =  0.8;
  static const double trackingWidest   =  1.0;
  static const double tracking12       =  1.2;
  static const double tracking15       =  1.5;
  static const double tracking20       =  2.0;
  static const double tracking30       =  3.0;
  static const double tracking40       =  4.0;
}