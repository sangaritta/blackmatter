import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class StorageService {
  StorageService();
  final db = FirebaseStorage.instance;

  // Store the current upload task
  UploadTask? _currentUploadTask;

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

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      // Wait for the original image upload to complete
      final snapshot = await uploadTask;
      final originalUrl = await snapshot.ref.getDownloadURL();

      // Do NOT resize or upload preview image (backend will handle this later)
      return {'originalUrl': originalUrl, 'previewUrl': ''};
    } on FirebaseException catch (e) {
      developer.log('Error uploading cover image: $e', name: 'StorageService');
      rethrow;
    } catch (e) {
      developer.log('Error uploading cover image: $e', name: 'StorageService');
      rethrow;
    }
  }

  Future<String?> getCoverImageUrl(
    String userId,
    String projectId,
    String productId,
  ) async {
    try {
      final path =
          'users/$userId/projects/$projectId/products/$productId/cover.jpg';
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

  Future<Map<String, String>> uploadAudioTrackFromBytes(
    Uint8List bytes,
    String userId,
    String projectId,
    String productId,
    String trackId,
    String fileName,
    Function(double) onProgress,
  ) async {
    try {
      final path = 'users/$userId/projects/$projectId/products/$productId/tracks/$trackId/$fileName';
      final metadata = SettableMetadata(contentType: 'audio/wav');
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
      developer.log('Error uploading audio track: $e', name: 'StorageService');
      rethrow;
    }
  }
}

StorageService st = StorageService();
