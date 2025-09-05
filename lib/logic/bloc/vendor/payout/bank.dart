// lib/data/models/vendor/payout/bank.dart
import 'package:equatable/equatable.dart';

class Bank extends Equatable {
  final String name;
  final String code;
  final String? imageUrl;

  const Bank({required this.name, required this.code, this.imageUrl});

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }

  @override
  List<Object?> get props => [name, code, imageUrl];
}