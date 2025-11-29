class KorraException implements Exception {
  final String message; // Friendly message for the user
  final String? technicalDetails; // Raw error for developer logs

  KorraException(this.message, {this.technicalDetails});

  @override
  String toString() => message; 
}