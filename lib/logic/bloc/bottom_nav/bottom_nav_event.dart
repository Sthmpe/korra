import 'package:equatable/equatable.dart';

abstract class BottomNavEvent extends Equatable {
  const BottomNavEvent();
  @override
  List<Object?> get props => [];
}

class BottomNavChanged extends BottomNavEvent {
  final int index;
  const BottomNavChanged(this.index);
  @override
  List<Object?> get props => [index];
}
