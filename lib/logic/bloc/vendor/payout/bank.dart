// lib/data/models/vendor/payout/bank.dart
import 'package:equatable/equatable.dart';

class Bank extends Equatable {
  final String name;
  final String code;
  final String? logoUrl;

  const Bank({required this.name, required this.code, this.logoUrl});

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      logoUrl: map['logo_url'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, code, logoUrl];
}