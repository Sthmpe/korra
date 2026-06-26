import 'package:flutter/material.dart';

import 'colors.dart';

/// Design tokens for all toggle, switch, and checkbox variants.
class KorraToggles {
  // -- Material Switch -------------------------------------------------
  // activeColor = thumb color when on; activeTrackColor = track when on
  static const Color switchThumbOn   = Colors.white;
  static const Color switchTrackOn   = KorraColors.brand;

  // -- SwitchListTile --------------------------------------------------
  // Uses activeColor for both thumb and track highlight
  static const Color switchListTileActive = KorraColors.brand;

  // -- Material Checkbox -----------------------------------------------
  static const Color checkboxActive = KorraColors.brand;
  static const double checkboxSize  = 24.0; // apply .w in widgets
  static const double checkboxRadius = 4.0; // apply .r in widgets

  static OutlinedBorder checkboxShape({double radius = checkboxRadius}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      );

  // -- Custom AnimatedContainer Checkbox (terms agreement) -------------
  static const double customCheckSize     = 24.0; // apply .w
  static const double customCheckRadius   = 6.0;  // apply .r
  static const double customCheckBorder   = 2.0;
  static const double customCheckIconSize = 16.0; // apply .sp

  static Color customCheckBg({required bool checked}) =>
      checked ? KorraColors.brand : Colors.white;

  static Color customCheckBorderColor({required bool checked}) =>
      checked ? KorraColors.brand : const Color(0xFFD1D5DB); // grey-300

  // -- Icon-based radio selector (store credit row) --------------------
  static const double radioIconCheckedSize   = 20.0; // apply .sp
  static const double radioIconUncheckedSize = 24.0; // apply .sp
  static const Color  radioIconChecked       = Color(0xFF16A34A); // green-600
  static const Color  radioIconUnchecked     = Color(0xFF9CA3AF); // grey-400

  // -- Segmented presence tab (online / physical / both) ---------------
  static const double presenceTabRadius = 10.0;   // apply .r
  static const Color  presenceTabBg     = Color(0xFFF2F2F7); // outer container
  static const Color  presenceTabActive = Colors.white;
  static const Color  presenceTabTextActive   = Color(0xFF111111);
  static const Color  presenceTabTextInactive = Color(0xFF8E8E93);
}
