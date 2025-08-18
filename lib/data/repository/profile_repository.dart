import 'dart:async';
import '../models/user_profile.dart';

class ProfileRepository {
  Future<UserProfile> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return UserProfile.demo();
  }

  Future<UserProfile> toggleBiometrics(UserProfile p, bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return p.copyWith(biometricsEnabled: enabled);
  }

  Future<UserProfile> toggleAutopayDefault(UserProfile p, bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return p.copyWith(autopayDefault: enabled);
  }

  Future<UserProfile> toggleNotif(
    UserProfile p, {bool? push, bool? email, bool? sms}
  ) async {
    await Future.delayed(const Duration(milliseconds: 220));
    return p.copyWith(
      pushNotif:  push  ?? p.pushNotif,
      emailNotif: email ?? p.emailNotif,
      smsNotif:   sms   ?? p.smsNotif,
    );
  }

  Future<UserProfile> changeReminderCadence(UserProfile p, String cadence) async {
    await Future.delayed(const Duration(milliseconds: 220));
    return p.copyWith(reminderCadence: cadence);
  }

  Future<void> logout() async => Future.delayed(const Duration(milliseconds: 250));
  Future<void> deleteAccount() async => Future.delayed(const Duration(milliseconds: 400));
}
