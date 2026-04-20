import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // 👈 IMPORT FOR kIsWeb
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
  bool _isProcessing = false;

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final bloc = context.read<ImageBloc>();

    try {
      final picked = await picker.pickMultiImage();

      if (picked.isNotEmpty) {
        if (picked.length > 5) {
          showAppSnackbar("You can only select up to 5 images.", SnackbarType.warning);
          return;
        }

        if (picked.length < 1) {
          showAppSnackbar("Please select at least 1 image.", SnackbarType.warning);
          return;
        }

        setState(() => _isProcessing = true);

        // ======================================================
        // 🚀 PLATFORM CHECK (WEB FIX)
        // ======================================================
        if (kIsWeb) {
          // ON WEB: We cannot use File() or ImageConverter (dart:io).
          // We pass the XFile directly to the bloc.
          bloc.add(AddImages(picked)); 
        } else {
          // ON MOBILE: We perform conversion to reduce size/change format
          final convertedFiles = await Future.wait(
            picked.map((e) => ImageConverter.toWebP(File(e.path))),
          );
          bloc.add(AddImages(convertedFiles));
        }
        // ======================================================

      }
    } catch (e) {
      showAppSnackbar("Error processing images", SnackbarType.error);
    } finally {
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

        int itemCount = dataCount + (widget.editable ? 1 : 0);

        if (itemCount == 1 && !_isProcessing && dataCount == 0) {
          return widget.editable ? _buildBigPlaceholder() : const SizedBox();
        }

        return CarouselSlider.builder(
          itemCount: itemCount,
          options: CarouselOptions(
            height: 120.h,
            viewportFraction: 0.4,
            enableInfiniteScroll: false,
            padEnds: false,
          ),
          itemBuilder: (context, index, _) {
            if (index == itemCount - 1) {
              if (_isProcessing) {
                return _buildLoadingBox(); 
              } else if (widget.editable) {
                return _buildAddButton();  
              }
            }

            if (showLocal) {
              if (index >= state.images.length) return const SizedBox();
              // Pass the dynamic image (File or XFile)
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

  // ... (LoadingBox, BigPlaceholder, AddButton - NO CHANGES NEEDED) ...
  Widget _buildLoadingBox() {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      height: 120.h,
      width: 120.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: Colors.grey.shade50,
        //border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: SizedBox(
          width: 24.w, height: 24.w, 
          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.grey)
        ),
      ),
    );
  }

  Widget _buildBigPlaceholder() {
    return GestureDetector(
      onTap: () => _pickImages(context),
      child: Container(
        height: 120.h,
        width: 120.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.grey.shade100,
          //border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.gallery_add, size: 32.sp, color: Colors.grey.shade600),
            SizedBox(height: 8.h),
            Text("Add Photos", style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600))
          ],
        ),
      ),
    );
  }

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
        child: Center(child: Icon(Iconsax.add, size: 32.sp, color: Colors.black)),
      ),
    );
  }

  // --- WIDGET HELPER: Local Image (UPDATED FOR WEB) ---
  Widget _buildLocalImage(dynamic imageFile, int index) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(right: 12.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            // ✅ CONDITIONAL RENDERING FOR WEB vs MOBILE
            child: kIsWeb 
              ? Image.network(
                  imageFile.path, // On Web, XFile.path is a blob URL
                  width: 120.w,
                  height: 120.h,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  imageFile as File, // On Mobile, it is a File
                  width: 120.w,
                  height: 120.h,
                  fit: BoxFit.cover,
                ),
          ),
        ),
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

  // ... (Network Image - NO CHANGES NEEDED) ...
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