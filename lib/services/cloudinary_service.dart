import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Replace with your real Cloudinary values (Settings -> Upload in the dashboard).
const _cloudName = 'fpwzrlte';
const _uploadPreset = 'bai_uploads'; // must be set to "Unsigned"

class CloudinaryService {
  final _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  /// Returns the uploaded image's URL, or null if the upload failed.
  /// [folder] organizes uploads in your Cloudinary media library
  /// (e.g. 'bai/receipts' for subscription receipts).
  Future<String?> upload(File file, {String? folder}) async {
    try {
      final res = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image, folder: folder),
      );
      return res.secureUrl;
    } catch (e) {
      // ignore: avoid_print
      print('Cloudinary upload failed: $e');
      return null;
    }
  }
}