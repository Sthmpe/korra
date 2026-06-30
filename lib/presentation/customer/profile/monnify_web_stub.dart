// Stub implementation for mobile platforms where dart:js is unavailable.
void initializeMonnifyWeb({
  required double amount,
  required String apiKey,
  required String contractCode,
  required String paymentReference,
  required String email,
  required String name,
  required String uid,
  required void Function() onComplete,
  required void Function() onClose,
}) {
  // No-op on mobile
}
