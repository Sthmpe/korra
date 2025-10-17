import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'image_event.dart';
part 'image_state.dart';

class ImageBloc extends Bloc<ImageEvent, ImageState> {
  ImageBloc() : super(const ImageState()) {
    on<AddImages>(_onAddImages);
    on<RemoveImage>(_onRemoveImage);
    on<ResetState>(_onResetState);
  }
  void _onResetState(ResetState event, Emitter<ImageState> emit) {
    emit(
      state.copyWith(
        errorMessage: '',
        images: [],
        cloudUrls: [],
        isUploading: false,
      ),
    );
  }

  void _onAddImages(AddImages event, Emitter<ImageState> emit) {
    emit(
      state.copyWith(images: List.of(state.images)..addAll(event.newImages)),
    );
  }

  void _onRemoveImage(RemoveImage event, Emitter<ImageState> emit) {
    final updated = [...state.images]..removeAt(event.index);
    emit(state.copyWith(images: updated));
  }
 }
