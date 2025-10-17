import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class ImageUploadBox extends StatelessWidget {
  final List<String> imagesUrl;
  final bool editable;
  const ImageUploadBox({
    super.key,
    required this.imagesUrl,
    this.editable = true,
  });

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final bloc = context.read<ImageBloc>(); // capture before await

    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      // Enforce max of 5
      if (picked.length > 5) {
        showAppSnackbar(
          "You can only select up to 5 images.",
          SnackbarType.warning,
        );
        return;
      }

      // Enforce min of 3
      if (picked.length < 3) {
        showAppSnackbar(
          "Please select at least 3 images.",
          SnackbarType.warning,
        );
        return;
      }

      final files = picked.map((e) => File(e.path)).toList();
      bloc.add(AddImages(files));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageBloc, ImageState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (imagesUrl.isNotEmpty && state.images.isEmpty) ...[
              // Image Carousel
              Expanded(
                child: CarouselSlider.builder(
                  itemCount: imagesUrl.length + 1,
                  options: CarouselOptions(
                    height: 120.h,
                    viewportFraction: 0.4,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: false,
                    initialPage: 0,
                    padEnds: false,
                  ),
                  itemBuilder: (context, index, _) {
                    if (index == imagesUrl.length) {
                      return editable
                          ? GestureDetector(
                              onTap: () => _pickImages(context),
                              child: Container(
                                height: 120.h,
                                width: 120.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24.r),
                                  color: Colors.grey.shade100,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40.sp,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final image = imagesUrl[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: CachedNetworkImage(
                            imageUrl: image,
                            width: 120.w,
                            height: 120.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Positioned(
                        //   right: 4,
                        //   top: 4,
                        //   child: GestureDetector(
                        //     onTap: () => context.read<ImageBloc>().add(
                        //       RemoveImage(index),
                        //     ),
                        //     child: Container(
                        //       decoration: BoxDecoration(
                        //         color: Colors.black45,
                        //         shape: BoxShape.circle,
                        //       ),
                        //       padding: const EdgeInsets.all(4),
                        //       child: const Icon(
                        //         Icons.close,
                        //         color: Colors.white,
                        //         size: 16,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    );
                  },
                ),
              ),
            ],

            if (state.images.isEmpty && editable && imagesUrl.isEmpty) ...[
              GestureDetector(
                onTap: () => _pickImages(context),
                child: Container(
                  height: 120.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    color: Colors.grey.shade100,
                  ),
                  child: state.images.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40.sp,
                          ),
                        )
                      : null,
                ),
              ),
            ],

            if (state.images.isNotEmpty) ...[
              // Image Carousel
              Expanded(
                child: CarouselSlider.builder(
                  itemCount: state.images.length,
                  options: CarouselOptions(
                    height: 120.h,
                    viewportFraction: 0.4,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: false,
                    initialPage: 0,
                    padEnds: false,
                  ),
                  itemBuilder: (context, index, _) {
                    final image = state.images[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: Image.file(
                            image,
                            width: 120.w,
                            height: 120.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => context.read<ImageBloc>().add(
                              RemoveImage(index),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
