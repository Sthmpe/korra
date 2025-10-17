part of 'image_bloc.dart';

abstract class ImageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddImages extends ImageEvent {
  final List<File> newImages;
  AddImages(this.newImages);

  @override
  List<Object?> get props => [newImages];
}

class RemoveImage extends ImageEvent {
  final int index;
  RemoveImage(this.index);

  @override
  List<Object?> get props => [index];
}

class ResetState extends ImageEvent {}
