// -----------------------------------------------------------------------------
// File: lib/logic/utils/date_formatters.dart
// Project: Korra – Vendor Onboarding
// Summary:
//   Date formatting helpers used by the signup flow.
//   - formatDateOfBirthForBvn:  "DD-MMM-YYYY"  (e.g., "03-Oct-1993")
//   - formatDateOfBirthIso:     "YYYY-MM-DD"   (e.g., "1990-04-08")
//
// Notes:
//   • Month names are hard-coded in English to match Monnify's BVN expectation.
//   • Both functions left-pad day/month to two digits and year to four.
// -----------------------------------------------------------------------------

/// Returns DOB as "DD-MMM-YYYY", e.g., "03-Oct-1993".
String formatDateOfBirthForBvn(DateTime date) {
  const List<String> monthNames = <String>[
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  final String day   = date.day.toString().padLeft(2, '0');
  final String month = monthNames[date.month - 1];
  final String year  = date.year.toString().padLeft(4, '0');

  return '$day-$month-$year';
}

/// Returns DOB as ISO "YYYY-MM-DD", e.g., "1990-04-08".
String formatDateOfBirthIso(DateTime date) {
  final String year  = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day   = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
