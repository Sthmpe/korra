import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // 1. If empty, return empty
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 2. Remove all existing commas and non-numeric chars (except dot)
    //    We basically reset to "raw" number to re-format it cleanly.
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // 3. Prevent multiple dots (e.g. 1.5.0)
    if ('.'.allMatches(newText).length > 1) {
      return oldValue; 
    }

    // 4. Split Integer and Decimal parts
    List<String> parts = newText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // 5. Limit Decimal to 2 digits
    if (decimalPart != null && decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2); // Truncate
    }

    // 6. Format Integer Part with Commas
    //    We parse it to int to remove leading zeros (005 -> 5), then format.
    if (integerPart.isNotEmpty) {
      try {
        final number = int.parse(integerPart);
        final formatter = NumberFormat('#,###', 'en_US');
        integerPart = formatter.format(number);
      } catch (e) {
        // If integer is too big or invalid, keep as is
      }
    }

    // 7. Reassemble the Text
    String formattedText = integerPart;
    if (parts.length > 1) {
      // Logic: User typed a dot
      formattedText += '.$decimalPart'; 
    } else if (newText.endsWith('.')) {
      // Logic: User JUST typed the dot
      formattedText += '.'; 
    }

    // 8. Return with cursor at the end (Standard for Amount Inputs)
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Allow only "123" or "123." or "123.45"
    final regEx = RegExp(r'^\d*\.?\d{0,2}$');
    
    if (regEx.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}