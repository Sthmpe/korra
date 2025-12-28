import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');

    String clean = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Prevent multiple dots
    if (clean.indexOf('.') != clean.lastIndexOf('.')) return oldValue; 

    List<String> parts = clean.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    if (integerPart.isNotEmpty) {
      final formatter = NumberFormat("#,###");
      try {
        integerPart = formatter.format(int.parse(integerPart));
      } catch (e) {}
    }

    String newText = integerPart;
    if (parts.length > 1 || clean.endsWith('.')) {
      newText += '.${decimalPart ?? ""}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
