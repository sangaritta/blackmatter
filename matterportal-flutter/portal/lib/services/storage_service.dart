import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:developer' as developer;

class StorageService {
  StorageService();
  final db = FirebaseStorage.instance;

  // Store the current upload task
  UploadTask? _currentUploadTask;

  /// Helper method to resize an image to a specific size using the image package
  Future<Uint8List> _resizeImage(
    Uint8List imageBytes,
    int targetWidth,
    int targetHeight,
  ) async {
    try {
      // Decode the image using the image package
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize the image to the target dimensions
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode the resized image as PNG
      final Uint8List pngBytes = Uint8List.fromList(
        img.encodePng(resizedImage),
      );

      return pngBytes;
    } catch (e) {
      developer.log('Error resizing image: $e', name: 'StorageService');
      // If resizing fails, return the original image
      return imageBytes;
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    File file,
    String path,
    void Function(double) onProgress,
  ) async {
    try {
      var fileRef = db.ref().child(path);
      _currentUploadTask = fileRef.putFile(file);

      // Listen to the upload task for progress reporting
      _currentUploadTask!.snapshotEvents.listen((event) {
        onProgress(event.bytesTransferred / event.totalBytes);
      });

      var snapshot = await _currentUploadTask!;
      var downloadUrl = await snapshot.ref.getDownloadURL();
      return {'url': downloadUrl, 'path': path};
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Map<String, String>> uploadFileFromBytes(
    Uint8List bytes,
    String path,
    Function(double) onProgress, {
    String? mimeType,
  }) async {
    try {
      final metadata = SettableMetadata(contentType: mimeType);

      final ref = db.ref().child(path);
      final uploadTask = ref.putData(bytes, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {'url': downloadUrl, 'path': path};
    } catch (e) {
      developer.log('Error uploading file: $e', name: 'StorageService');
      rethrow;
    }
  }

  // Method to cancel the current upload
  void cancelUpload() {
    _currentUploadTask?.cancel();
  }

  Future<Map<String, String>> uploadCoverImage(
    String userId,
    String projectId,
    String productId,
    Uint8List imageBytes, {
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Upload original image
      final originalPath =
          'users/$userId/projects/$projectId/products/$productId/cover.jpg';
      final originalRef = db.ref().child(originalPath);

      final uploadTask = originalRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen to upload progress for the original image
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      // Wait for the original image upload to complete
      await uploadTask;
      final originalUrl = await originalRef.getDownloadURL();

      // 2. Create and upload preview image (300x300)
      try {
        final previewPath =
            'users/$userId/projects/$projectId/products/$productId/cover_preview.jpg';
        final previewRef = db.ref().child(previewPath);

        // Resize the image to 300x300
        final previewImageBytes = await _resizeImage(imageBytes, 300, 300);
        // Upload the preview image
        await previewRef.putData(
          previewImageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final previewUrl = await previewRef.getDownloadURL();

        // Return both URLs
        return {'originalUrl': originalUrl, 'previewUrl': previewUrl};
      } catch (e) {
        developer.log(
          'Error creating preview image: $e',
          name: 'StorageService',
        );
        // If preview fails, still return the original
        return {
          'originalUrl': originalUrl,
          'previewUrl': '', // Return empty string if preview fails
        };
      }
    } catch (e) {
      developer.log('Error uploading cover image: $e', name: 'StorageService');
      return {'originalUrl': '', 'previewUrl': ''};
    }
  }

  Future<String?> getCoverImageUrl(
    String userId,
    String projectId,
    String productId,
  ) async {
    try {
      final path =
          'catalog/$userId/projects/$projectId/products/$productId/art.jpg';
      var fileRef = db.ref().child(path);
      return await fileRef.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> getDownloadURL(String path) async {
    try {
      var fileRef = db.ref().child(path);
      return await fileRef.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}

StorageService st = StorageService();
