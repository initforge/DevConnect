import 'package:image_picker/image_picker.dart';

class ImageCompressionService {
  ImageCompressionService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int maxUploadBytes = 10 * 1024 * 1024;
  static const double defaultMaxDimension = 1200;
  static const int defaultQuality = 82;

  Future<XFile?> pickCompressedImage({
    ImageSource source = ImageSource.gallery,
    double maxWidth = defaultMaxDimension,
    double maxHeight = defaultMaxDimension,
    int imageQuality = defaultQuality,
  }) {
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  Future<bool> isUnderUploadLimit(XFile file) async {
    final length = await file.length();
    return length <= maxUploadBytes;
  }
}
