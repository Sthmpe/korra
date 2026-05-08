import 'package:flutter/material.dart';

import 'colors.dart';

/// Design tokens for all button variants across the app.
class KorraButtons {
  // -- Heights (apply .h in widgets) ------------------------------------
  static const double heightLg        = 56.0; // failure sheet buttons
  static const double heightMd        = 54.0; // primary CTA (matches KorraSizes.buttonHeight)
  static const double heightSm        = 52.0; // compact variant (failure sheet v2)
  static const double heightIconSquare = 54.0; // square icon-only back button

  // -- Border radii (apply .r in widgets) -------------------------------
  static const double radiusMd    = 16.0; // main button radius - most buttons
  static const double radiusSm    = 14.0; // compact variant - sgnup_failure_sheet
  static const double radiusField = 12.0; // forgot-password / reset-link buttons

  // -- Loading spinner sizes (apply .h / .w in widgets) -----------------
  static const double spinnerSm     = 20.0;
  static const double spinnerMd     = 22.0;
  static const double spinnerLg     = 24.0;
  static const double spinnerStroke     = 2.5;
  static const double spinnerStrokeThin = 2.0;

  // -- Borders ----------------------------------------------------------
  static const Color borderLight = Color(0xFFE5E7EB); // outlined / google button

  // -- Primary button ---------------------------------------------------
  static BoxDecoration primaryDecoration({bool disabled = false}) => BoxDecoration(
    color: disabled
        ? KorraColors.brand.withValues(alpha: 0.5)
        : KorraColors.brand,
    borderRadius: BorderRadius.circular(radiusMd),
  );

  static BoxDecoration primaryDecorationWithShadow({bool disabled = false}) => BoxDecoration(
    color: disabled
        ? KorraColors.brand.withValues(alpha: 0.7)
        : KorraColors.brand,
    borderRadius: BorderRadius.circular(radiusMd),
    boxShadow: disabled
        ? []
        : [
            BoxShadow(
              color: KorraColors.brand.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
  );

  // -- ElevatedButton styles -------------------------------------------
  static ButtonStyle primaryStyle({double radius = radiusMd}) =>
      ElevatedButton.styleFrom(
        backgroundColor: KorraColors.brand,
        disabledBackgroundColor: KorraColors.brand.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  static ButtonStyle softGreyStyle({double radius = radiusMd}) =>
      ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // -- OutlinedButton styles -------------------------------------------
  static ButtonStyle outlinedLightStyle({double radius = radiusMd}) =>
      OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 0,
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  static ButtonStyle outlinedBorderStyle({double radius = radiusMd}) =>
      OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        side: BorderSide(color: KorraColors.border),
      );

  // -- FilledButton styles ---------------------------------------------
  static ButtonStyle filledStyle({double radius = radiusField}) =>
      FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // -- TextButton styles -----------------------------------------------
  static ButtonStyle cancelStyle({double radius = radiusMd}) =>
      TextButton.styleFrom(
        backgroundColor: const Color(0xFFF2F2F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
