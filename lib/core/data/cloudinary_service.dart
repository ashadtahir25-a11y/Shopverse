import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/cloudinary_config.dart';

/// Uploads images directly from the Flutter app to Cloudinary using an
/// UNSIGNED upload preset (no API secret ever touches client code — see
/// cloudinary_config.dart for setup). Returns the resulting HTTPS URL,
/// which is what gets stored on the relevant Firestore document
/// (`users/{uid}.avatarUrl`, a review's `imageUrls`, etc.)
class CloudinaryService {
  final Dio _dio = Dio();

  /// [folder] groups uploads in the Cloudinary media library, e.g.
  /// 'avatars', 'reviews', 'products' — purely organizational.
  Future<String> uploadImageBytes(Uint8List bytes, {required String fileName, String folder = 'shopverse'}) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
        'Cloudinary is not configured yet. Run the app with --dart-define=CLOUDINARY_CLOUD_NAME=... '
        '--dart-define=CLOUDINARY_UPLOAD_PRESET=... (see lib/core/config/cloudinary_config.dart)',
      );
    }

    final url = 'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'upload_preset': CloudinaryConfig.uploadPreset,
      'folder': folder,
    });

    final response = await _dio.post(url, data: formData);

    if (response.statusCode == 200 && response.data is Map) {
      final secureUrl = response.data['secure_url'] as String?;
      if (secureUrl != null) return secureUrl;
    }

    throw StateError('Cloudinary upload failed: ${response.statusCode} ${response.data}');
  }
}

final cloudinaryService = CloudinaryService();
