import 'package:intl/intl.dart';

class KorraValidators {
  static String? name(String? v, {String field = 'Name'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final ok = RegExp(r"^[A-Za-z][A-Za-z' -]{1,29}$").hasMatch(v.trim());
    return ok ? null : 'Enter a valid $field';
  }

  static String? optionalName(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r"^[A-Za-z][A-Za-z' -]{1,29}$").hasMatch(v.trim());
    return ok ? null : 'Enter a valid name';
  }

  static String? phoneNg(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';

    // remove spaces/dashes etc. but keep leading '+'
    final s = v.trim().replaceAll(RegExp(r'[^\d\+]'), '');

    final rx = RegExp(
      r'^(?:' // start group
      r'0(?:70|71|80|81|90|91)\d{8}' // local: 0 + (70/71/80/81/90/91) + 8 digits
      r'|' // OR
      r'(?:\+234|234)(?:70|71|80|81|90|91)\d{8}' // intl: +234/234 + (70/71/80/81/90/91) + 8 digits
      r')$',
    );

    return rx.hasMatch(s)
        ? null
        : 'Enter a valid Nigerian phone (e.g. 070..., 080..., +23470..., 23470...)';
  }


  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  static String? nin(String? v) {
    if (v == null || v.trim().isEmpty) return 'NIN is required';
    return RegExp(r'^\d{11}$').hasMatch(v.trim()) ? null : 'NIN must be 11 digits';
  }

  static String? bvn(String? v) {
    if (v == null || v.trim().isEmpty) return 'BVN is required';
    return RegExp(r'^\d{11}$').hasMatch(v.trim()) ? null : 'BVN must be 11 digits';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    final ok = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(v);
    return ok ? null : 'Min 8 chars with letters & numbers';
  }

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    return v == original ? null : 'Passwords don’t match';
  }

  static String? dob(DateTime? d) {
    if (d == null) return 'Date of birth is required';
    final now = DateTime.now();
    final minDate = DateTime(now.year - 18, now.month, now.day);
    return d.isBefore(minDate) ? null : 'You must be 18 or older';
  }

  static String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
