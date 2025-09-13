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
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, do nothing.
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Get the clean number string by removing all non-digit characters.
    final cleanString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanString.isEmpty) {
      return const TextEditingValue();
    }
    
    // 2. Parse the clean string into a number.
    final number = int.parse(cleanString);

    // 3. Format the number with thousand separators.
    final formatter = NumberFormat('#,##0', 'en_US');
    final formattedString = formatter.format(number);

    // 4. Return the new TextEditingValue with the formatted text and
    //    the cursor positioned correctly at the end.
    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}