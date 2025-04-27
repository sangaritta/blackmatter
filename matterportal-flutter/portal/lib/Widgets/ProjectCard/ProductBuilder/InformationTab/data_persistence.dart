import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portal/Models/product_data.dart';
import 'package:portal/Services/storage_service.dart';

/// Utility class for loading and saving product information
class DataPersistence {
  final Function(ProductData) onProductLoaded;
  final Function()? onProductSaved;
  final Function(String) onError;

  DataPersistence({
    required this.onProductLoaded,
    this.onProductSaved,
    required this.onError,
  });

  /// Load product data from Firestore
  Future<void> loadProductData({
    String? userId,
    required String projectId,
    required String productId,
  }) async {
    if (userId == null) {
      onError('User ID is null');
      return;
    }

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};
        ProductData product = ProductData.fromMap(data);
        onProductLoaded(product);
      }
    } catch (e) {
      onError('Error loading product: $e');
      rethrow;
    }
  }

  /// Save product information to Firestore
  Future<void> saveProductInformation({
    String? userId,
    required String projectId,
    required String productId,
    required ProductData productData,
    required Uint8List? imageBytes,
    required Function(double, double) onProgress,
  }) async {
    if (userId == null) {
      onError('User ID is null');
      return;
    }

    try {
      // Upload product image if changed
      if (imageBytes != null) {
        final imageUrls = await _uploadProductImage(
          userId: userId,
          productId: productId,
          imageBytes: imageBytes,
          onUploadProgress: (progress) {
            onProgress(progress, 0.0);
          },
        );

        // Create a new ProductData instance with the updated coverImage and previewArtUrl
        productData = ProductData(
          id: productData.id,
          releaseTitle: productData.releaseTitle,
          releaseVersion: productData.releaseVersion,
          primaryArtists: productData.primaryArtists,
          primaryArtistIds: productData.primaryArtistIds,
          metadataLanguage: productData.metadataLanguage,
          genre: productData.genre,
          subgenre: productData.subgenre,
          type: productData.type,
          price: productData.price,
          upc: productData.upc,
          uid: productData.uid,
          label: productData.label,
          cLine: productData.cLine,
          pLine: productData.pLine,
          cLineYear: productData.cLineYear,
          pLineYear: productData.pLineYear,
          coverImage: imageUrls['originalUrl'] ?? '',
          previewArtUrl: imageUrls['previewUrl'] ?? '',
          state: productData.state,
          autoGenerateUPC: productData.autoGenerateUPC,
        );
      }

      // Update progress
      onProgress(1.0, 0.3);

      // Generate UPC if needed
      if (productData.autoGenerateUPC) {
        // Create a new ProductData instance with the generated UPC

        productData = ProductData(
          id: productData.id,
          releaseTitle: productData.releaseTitle,
          releaseVersion: productData.releaseVersion,
          primaryArtists: productData.primaryArtists,
          primaryArtistIds: productData.primaryArtistIds,
          metadataLanguage: productData.metadataLanguage,
          genre: productData.genre,
          subgenre: productData.subgenre,
          type: productData.type,
          price: productData.price,
          upc: productData.upc,
          uid: productData.uid,
          label: productData.label,
          cLine: productData.cLine,
          pLine: productData.pLine,
          cLineYear: productData.cLineYear,
          pLineYear: productData.pLineYear,
          coverImage: productData.coverImage,
          state: productData.state,
          autoGenerateUPC: productData.autoGenerateUPC,
        );
      }

      // Update progress
      onProgress(1.0, 0.6);

      // Save product data to Firestore
      await FirebaseFirestore.instance
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .set(productData.toMap());

      // Update progress
      onProgress(1.0, 1.0);

      // Notify completion
      onProductSaved?.call();
    } catch (e) {
      onError('Error saving product: $e');
      rethrow;
    }
  }

  /// Upload product image to Firebase Storage
  Future<Map<String, String>> _uploadProductImage({
    required String userId,
    required String productId,
    required Uint8List imageBytes,
    required Function(double) onUploadProgress,
  }) async {
    try {
      // Use our storage service to upload both original and preview images
      final result = await st.uploadCoverImage(
        userId,
        productId,
        productId, // Product ID is used for both project and product
        imageBytes,
        onProgress: onUploadProgress,
      );

      // Return both URLs
      return {
        'originalUrl': result['originalUrl'] ?? '',
        'previewUrl': result['previewUrl'] ?? '',
      };
    } catch (e) {
      onError('Error uploading image: $e');
      rethrow;
    }
  }
}
