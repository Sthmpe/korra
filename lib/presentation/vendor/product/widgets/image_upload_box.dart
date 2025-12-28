import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../config/utils/image_converter.dart';
import '../../../../logic/bloc/vendor/image/image_bloc.dart';
import '../../../shared/widgets/show_app_snackbar.dart';

class ImageUploadBox extends StatefulWidget {
  final List<String> imagesUrl;
  final bool editable;

  const ImageUploadBox({
    super.key,
    required this.imagesUrl,
    this.editable = true,
  });

  @override
  State<ImageUploadBox> createState() => _ImageUploadBoxState();
}

class _ImageUploadBoxState extends State<ImageUploadBox> {
  // ✅ Local state to track conversion progress
  bool _isProcessing = false;

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final bloc = context.read<ImageBloc>();

    try {
      final picked = await picker.pickMultiImage();

      if (picked.isNotEmpty) {
        // Enforce max of 5
        if (picked.length > 5) {
          showAppSnackbar("You can only select up to 5 images.", SnackbarType.warning);
          return;
        }

        // Enforce min of 3
        if (picked.length < 3) {
          showAppSnackbar("Please select at least 3 images.", SnackbarType.warning);
          return;
        }

        // 1. TRIGGER LOADING STATE
        setState(() => _isProcessing = true);

        // 2. CONVERT IMAGES (Heavy Task)
        final convertedFiles = await Future.wait(
          picked.map((e) => ImageConverter.toWebP(File(e.path))),
        );

        // 3. SEND TO BLOC
        bloc.add(AddImages(convertedFiles));
      }
    } catch (e) {
      showAppSnackbar("Error processing images", SnackbarType.error);
    } finally {
      // 4. STOP LOADING STATE
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageBloc, ImageState>(
      builder: (context, state) {
        
        final bool showLocal = state.images.isNotEmpty;
        final int dataCount = showLocal ? state.images.length : widget.imagesUrl.length;

        // Calculate total items: Images + (Add Button OR Loader)
        // If processing, the loader replaces the Add Button slot
        int itemCount = dataCount + (widget.editable ? 1 : 0);

        // CASE 1: Empty State (Show Big Placeholder if not processing)
        if (itemCount == 1 && !_isProcessing && dataCount == 0) {
          return widget.editable ? _buildBigPlaceholder() : const SizedBox();
        }

        // CASE 2: Carousel List
        return CarouselSlider.builder(
          itemCount: itemCount,
          options: CarouselOptions(
            height: 120.h,
            viewportFraction: 0.4,
            enableInfiniteScroll: false,
            padEnds: false,
          ),
          itemBuilder: (context, index, _) {
            // A. LAST SLOT LOGIC (Either Loader or Add Button)
            if (index == itemCount - 1) {
              if (_isProcessing) {
                return _buildLoadingBox(); // ✅ Show Loader
              } else if (widget.editable) {
                return _buildAddButton();  // ✅ Show Add Button
              }
            }

            // B. IMAGE SLOT LOGIC
            if (showLocal) {
              // Safety check to prevent range error during rapid state changes
              if (index >= state.images.length) return const SizedBox();
              return _buildLocalImage(state.images[index], index);
            } else {
              if (index >= widget.imagesUrl.length) return const SizedBox();
              return _buildNetworkImage(widget.imagesUrl[index]);
            }
          },
        );
      },
    );
  }

  // --- WIDGET HELPER: Loading Box (Spinner) ---
  Widget _buildLoadingBox() {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      height: 120.h,
      width: 120.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: SizedBox(
          width: 24.w, 
          height: 24.w, 
          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.grey)
        ),
      ),
    );
  }

  // --- WIDGET HELPER: Big Placeholder (Initial State) ---
  Widget _buildBigPlaceholder() {
    return GestureDetector(
      onTap: () => _pickImages(context),
      child: Container(
        height: 120.h,
        width: 120.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.gallery_add, size: 32.sp, color: Colors.grey.shade600),
            SizedBox(height: 8.h),
            Text(
              "Add Photos",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: Small Add Button (End of list) ---
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _pickImages(context),
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        height: 120.h,
        width: 120.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Icon(Iconsax.add, size: 32.sp, color: Colors.black),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: Local Image (With Remove) ---
  Widget _buildLocalImage(File file, int index) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(right: 12.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Image.file(
              file,
              width: 120.w,
              height: 120.h,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Remove Button
        Positioned(
          top: 6.h,
          right: 18.w, 
          child: GestureDetector(
            onTap: () => context.read<ImageBloc>().add(RemoveImage(index)),
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 14.sp, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET HELPER: Network Image (Read Only display) ---
  Widget _buildNetworkImage(String url) {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 120.w,
          height: 120.h,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey.shade100),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}