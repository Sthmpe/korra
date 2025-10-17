import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, success, failure, logout }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? errorMessage;

  const ProfileState({
    required this.status,
    this.errorMessage,
  });

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  ProfileState copyWith({
    ProfileStatus? status,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
