part of 'image_bloc.dart';

class ImageState extends Equatable {
  final String errorMessage;
  final List<dynamic> images; // 👈 CHANGED from List<File> to List<dynamic>
  final List<String> cloudUrls;
  final bool isUploading;

  const ImageState({
    this.errorMessage = '',
    this.images = const [],
    this.cloudUrls = const [],
    this.isUploading = false,
  });

  ImageState copyWith({
    String? errorMessage,
    List<dynamic>? images,
    List<String>? cloudUrls,
    bool? isUploading,
  }) {
    return ImageState(
      errorMessage: errorMessage ?? this.errorMessage,
      images: images ?? this.images,
      cloudUrls: cloudUrls ?? this.cloudUrls,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  @override
  List<Object> get props => [errorMessage, images, cloudUrls, isUploading];
}