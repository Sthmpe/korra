class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;

  // status (you require both visible for now)
  final bool kycVerified;  // true
  final bool basicTier;    // true

  // wallet / payment
  final String walletBalanceText;    // "₦75,500.00"
  final String defaultMethodMasked;  // "•••• 4242"
  final bool autopayDefault;

  // preferences
  final bool pushNotif;
  final bool emailNotif;
  final bool smsNotif;
  final String reminderCadence;      // "Same day" | "1 day before" | "3 days before"

  // security
  final bool biometricsEnabled;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.kycVerified,
    required this.basicTier,
    required this.walletBalanceText,
    required this.defaultMethodMasked,
    required this.autopayDefault,
    required this.pushNotif,
    required this.emailNotif,
    required this.smsNotif,
    required this.reminderCadence,
    required this.biometricsEnabled,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    bool? kycVerified,
    bool? basicTier,
    String? walletBalanceText,
    String? defaultMethodMasked,
    bool? autopayDefault,
    bool? pushNotif,
    bool? emailNotif,
    bool? smsNotif,
    String? reminderCadence,
    bool? biometricsEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      kycVerified: kycVerified ?? this.kycVerified,
      basicTier: basicTier ?? this.basicTier,
      walletBalanceText: walletBalanceText ?? this.walletBalanceText,
      defaultMethodMasked: defaultMethodMasked ?? this.defaultMethodMasked,
      autopayDefault: autopayDefault ?? this.autopayDefault,
      pushNotif: pushNotif ?? this.pushNotif,
      emailNotif: emailNotif ?? this.emailNotif,
      smsNotif: smsNotif ?? this.smsNotif,
      reminderCadence: reminderCadence ?? this.reminderCadence,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    );
  }

  static UserProfile demo() => const UserProfile(
    id: 'u_1',
    name: 'Ola N. Ade',
    email: 'ola@example.com',
    phone: '09152540533',
    kycVerified: true,
    basicTier: true,
    walletBalanceText: '₦75,500.00',
    defaultMethodMasked: '•••• 4242',
    autopayDefault: false,
    pushNotif: true,
    emailNotif: false,
    smsNotif: true,
    reminderCadence: '1 day before',
    biometricsEnabled: true,
  );
}
