// lib/logic/utils/currency_formatter.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats a number into a currency string with specific rules.
///
/// - Integers are formatted with commas and no decimal places (e.g., 5000 -> "5,000").
/// - Doubles are formatted with commas and two decimal places (e.g., 5000.234 -> "5,000.23").
/// - Handles both `int` and `double` inputs gracefully.
String formatToCurrency(num value) {
  // Check if the number has a fractional part.
  // We check if the number modulo 1 is not zero.
  final bool hasDecimal = value % 1 != 0;

  if (hasDecimal) {
    // For doubles, use a pattern with two decimal places.
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(value);
  } else {
    // For integers, use a pattern with no decimal places.
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(value);
  }
}

/// A world-class input formatter that provides real-time, as-you-type
/// currency formatting (e.g., "1234567" -> "1,234,567").
/// Formatter for price input (adds commas, limits 2 decimals)
class CurrencyInputFormatter extends TextInputFormatter {
  final int decimalRange;
  CurrencyInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.isEmpty) return newValue.copyWith(text: '');

    String numeric = text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numeric.indexOf('.') != numeric.lastIndexOf('.')) {
      int first = numeric.indexOf('.');
      numeric =
          numeric.substring(0, first + 1) +
          numeric.substring(first + 1).replaceAll('.', '');
    }

    if (numeric.contains('.')) {
      List<String> parts = numeric.split('.');
      String intPart = parts[0].isEmpty ? '0' : parts[0];
      String decPart = parts.length > 1 ? parts[1] : '';

      if (decPart.length > decimalRange) {
        decPart = decPart.substring(0, decimalRange);
      }

      final formattedInt = NumberFormat(
        '#,##0',
        'en_US',
      ).format(int.parse(intPart));
      final out = decPart.isEmpty && text.endsWith('.')
          ? '$formattedInt.'
          : decPart.isEmpty
          ? formattedInt
          : '$formattedInt.$decPart';

      return TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: out.length),
      );
    } else {
      final formattedInt = NumberFormat(
        '#,##0',
        'en_US',
      ).format(int.parse(numeric.isEmpty ? '0' : numeric));
      return TextEditingValue(
        text: formattedInt,
        selection: TextSelection.collapsed(offset: formattedInt.length),
      );
    }
  }
}


String formatPrice(String priceText) {
    // Example input: "₦15000" or "₦ 15000"
    final cleaned = priceText.replaceAll(RegExp(r'[^\d.]'), ''); // removes ₦ and spaces
    final number = double.tryParse(cleaned);
    if (number == null) return priceText; // fallback if invalid

    final formattedNumber =
        NumberFormat('#,##0', 'en_NG').format(number); // e.g. 15,000
    return '₦$formattedNumber';
  }