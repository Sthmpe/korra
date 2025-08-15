import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {}
class PasteLinkSubmitted extends HomeEvent {
  final String value;
  const PasteLinkSubmitted(this.value);
  @override
  List<Object?> get props => [value];
}
class ScanRequested extends HomeEvent {}
class RequestLinkSheetOpened extends HomeEvent {}
