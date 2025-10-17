part of 'image_bloc.dart';

class ImageState extends Equatable {
  final List<File> images;
  final List<String> cloudUrls;
  final bool isUploading;
  final String? errorMessage;

  const ImageState({
    this.images = const [],
    this.cloudUrls = const [],
    this.isUploading = false,
    this.errorMessage = '',
  });

  ImageState copyWith({
    List<File>? images,
    List<String>? cloudUrls,
    bool? isUploading,
    String? errorMessage,
  }) {
    return ImageState(
      images: images ?? this.images,
      cloudUrls: cloudUrls ?? this.cloudUrls,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [images, cloudUrls, isUploading, errorMessage];
}