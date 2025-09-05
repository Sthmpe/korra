// lib/logic/utils/currency_formatter.dart

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