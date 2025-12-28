import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageConverter {
  static Future<File> toWebP(
    File file, {
    int quality = 92, // premium quality
  }) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      format: CompressFormat.webp,
      quality: quality,
    );

    if (result == null) {
      throw Exception('Image conversion failed');
    }

    return File(result.path);
  }
}