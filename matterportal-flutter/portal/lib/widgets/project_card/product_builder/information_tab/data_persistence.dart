import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portal/Services/storage_service.dart';
import 'package:portal/models/product.dart';
import 'package:portal/models/track.dart' as portal_track;

/// Utility class for loading and saving product information
class DataPersistence {
  final Function(Product) onProductLoaded;
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
        Product product = Product.fromMap(data, docSnapshot.id);
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
    required Product productData,
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

        // Create a new Product instance with the updated coverImage and previewArtUrl
        productData = Product(
          projectId: projectId,
          id: productData.id,
          userId: userId,
          uid: productData.uid,
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
          label: productData.label,
          cLine: productData.cLine,
          pLine: productData.pLine,
          cLineYear: productData.cLineYear,
          pLineYear: productData.pLineYear,
          coverImage: imageUrls['originalUrl'] ?? '',
          previewArtUrl: imageUrls['previewUrl'] ?? '',
          autoGenerateUPC: productData.autoGenerateUPC,
          trackCount: productData.tracks.length,
          tracks: productData.tracks,
          state: productData.state,
        );
      }

      // Update progress
      onProgress(1.0, 0.3);

      // Generate UPC if needed
      if (productData.autoGenerateUPC) {
        // Create a new ProductData instance with the generated UPC
        final generatedUPC = "AUTO";
        productData = Product(
          projectId: productData.projectId,
          id: productData.id,
          userId: userId,
          uid: productData.uid,
          releaseTitle: productData.releaseTitle,
          releaseVersion: productData.releaseVersion,
          primaryArtists: productData.primaryArtists,
          primaryArtistIds: productData.primaryArtistIds,
          metadataLanguage: productData.metadataLanguage,
          genre: productData.genre,
          subgenre: productData.subgenre,
          type: productData.type,
          price: productData.price,
          upc: generatedUPC,
          label: productData.label,
          cLine: productData.cLine,
          pLine: productData.pLine,
          cLineYear: productData.cLineYear,
          pLineYear: productData.pLineYear,
          coverImage: productData.coverImage,
          previewArtUrl: productData.previewArtUrl,
          autoGenerateUPC: productData.autoGenerateUPC,
          trackCount: productData.tracks.length,
          tracks: productData.tracks,
          state: productData.state,
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

  /// Save product with tracks
  Future<void> saveProductWithTracks({
    required Product product,
    required List<portal_track.Track> tracks,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    // Save the product
    final productRef = firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .doc(product.projectId)
        .collection('products')
        .doc(product.id);

    await productRef.set(product.toMap());

    // Save each track under the product's 'tracks' subcollection
    final tracksCollection = productRef.collection('tracks');
    final batch = firestore.batch();
    for (final track in tracks) {
      final trackRef = tracksCollection.doc(track.id);
      batch.set(trackRef, track.toMap());
    }
    await batch.commit();
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

extension ProductMapExtension on Product {
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'id': id,
      'userId': userId,
      'uid': uid,
      'releaseTitle': releaseTitle,
      'releaseVersion': releaseVersion,
      'primaryArtists': primaryArtists,
      'primaryArtistIds': primaryArtistIds,
      'metadataLanguage': metadataLanguage,
      'genre': genre,
      'subgenre': subgenre,
      'type': type,
      'price': price,
      'upc': upc,
      'label': label,
      'cLine': cLine,
      'pLine': pLine,
      'cLineYear': cLineYear,
      'pLineYear': pLineYear,
      'autoGenerateUPC': autoGenerateUPC,
      'previewArtUrl': previewArtUrl,
      'trackCount': trackCount,
      'tracks': tracks.map((t) => t.toMap()).toList(),
    };
  }
}

extension TrackMapExtension on portal_track.Track {
  Map<String, dynamic> toMap() {
    return {
      'trackNumber': trackNumber,
      'title': title,
      'version': version,
      'isExplicit': isExplicit,
      'primaryArtists': primaryArtists,
      'primaryArtistIds': primaryArtistIds,
      'featuredArtists': featuredArtists,
      'featuredArtistIds': featuredArtistIds,
      'genre': genre,
      'performersWithRoles': performersWithRoles,
      'songwritersWithRoles': songwritersWithRoles,
      'productionWithRoles': productionWithRoles,
      'remixers': remixers,
      'ownership': ownership,
      'country': country,
      'nationality': nationality,
      'isrc': isrc,
      'uid': uid,
      'artworkUrl': artworkUrl,
      'downloadUrl': downloadUrl,
      'lyrics': lyrics,
      'syncedLyrics': syncedLyrics,
      'productId': productId,
      'userId': userId,
      'name': name,
      'fileName': fileName,
      'storagePath': storagePath,
      'isrcCode': isrcCode,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }
}
