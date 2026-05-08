import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'sizes.dart';

/// EdgeInsets tokens. All are getters - flutter_screenutil .r/.w/.h
/// requires ScreenUtil.init before evaluation.
class KorraPaddings {
  // -- All sides --------------------------------------------------------
  static EdgeInsets get all4  => EdgeInsets.all(KorraSizes.s4.r);
  static EdgeInsets get all6  => EdgeInsets.all(KorraSizes.s6.r);
  static EdgeInsets get all8  => EdgeInsets.all(KorraSizes.s8.r);
  static EdgeInsets get all12 => EdgeInsets.all(KorraSizes.s12.r);
  static EdgeInsets get all16 => EdgeInsets.all(KorraSizes.s16.r);
  static EdgeInsets get all20 => EdgeInsets.all(KorraSizes.s20.r);
  static EdgeInsets get all24 => EdgeInsets.all(KorraSizes.s24.r);

  // -- Horizontal only --------------------------------------------------
  static EdgeInsets get h12 => EdgeInsets.symmetric(horizontal: KorraSizes.s12.w);
  static EdgeInsets get h16 => EdgeInsets.symmetric(horizontal: KorraSizes.s16.w);
  static EdgeInsets get h20 => EdgeInsets.symmetric(horizontal: KorraSizes.s20.w);
  static EdgeInsets get h24 => EdgeInsets.symmetric(horizontal: KorraSizes.s24.w);

  // -- Vertical only ----------------------------------------------------
  static EdgeInsets get v8  => EdgeInsets.symmetric(vertical: KorraSizes.s8.h);
  static EdgeInsets get v12 => EdgeInsets.symmetric(vertical: KorraSizes.s12.h);
  static EdgeInsets get v14 => EdgeInsets.symmetric(vertical: KorraSizes.s14.h);
  static EdgeInsets get v16 => EdgeInsets.symmetric(vertical: KorraSizes.s16.h);
  static EdgeInsets get v24 => EdgeInsets.symmetric(vertical: KorraSizes.s24.h);

  // -- Symmetric (h + v pairs) ------------------------------------------
  // h16 v14 - default input field content padding (app_theme.dart)
  static EdgeInsets get inputContent =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s16.w, vertical: KorraSizes.s14.h);

  // h16 v16 - snackbar / notice card padding
  static EdgeInsets get card16 =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s16.w, vertical: KorraSizes.s16.h);

  // h20 v16 - standard list tile content
  static EdgeInsets get tile =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s20.w, vertical: KorraSizes.s16.h);

  // h16 v8 - compact list tile
  static EdgeInsets get tileCompact =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s16.w, vertical: KorraSizes.s8.h);

  // h8 v4 - status badge / chip inner padding
  static EdgeInsets get chip =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s8.w, vertical: KorraSizes.s4.h);

  // h16 v8 - pill badge (store balance customers pill)
  static EdgeInsets get pill =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s16.w, vertical: KorraSizes.s8.h);

  // h4 v2 - tight badge / count chip
  static EdgeInsets get badge =>
      EdgeInsets.symmetric(horizontal: KorraSizes.s4.w, vertical: KorraSizes.s2.h);

  // -- Page layout ------------------------------------------------------
  // Full page horizontal margin - matches KorraSizes.gutter
  static EdgeInsets get pageH =>
      EdgeInsets.symmetric(horizontal: KorraSizes.gutter.w);

  // Full page padding (h20 + v24) - standard screen body padding
  static EdgeInsets get page =>
      EdgeInsets.symmetric(
        horizontal: KorraSizes.gutter.w,
        vertical: KorraSizes.s24.h,
      );

  // -- Bottom sheet -----------------------------------------------------
  // fromLTRB 24 12 24 24 - standard bottom sheet inner padding
  static EdgeInsets get sheet =>
      EdgeInsets.fromLTRB(
        KorraSizes.s24.w, KorraSizes.s12.h,
        KorraSizes.s24.w, KorraSizes.s24.h,
      );

  // -- Only sides -------------------------------------------------------
  static EdgeInsets get bottomNav => EdgeInsets.only(bottom: KorraSizes.s8.h);
  static EdgeInsets get topBar    => EdgeInsets.only(top: KorraSizes.s12.h);
}
