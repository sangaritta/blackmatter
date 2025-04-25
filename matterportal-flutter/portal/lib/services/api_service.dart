import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:portal/models/index_entry.dart';
import 'package:portal/models/product.dart';
import 'package:portal/models/project.dart';
import 'package:portal/models/track.dart';

const Map<String, String> platformIds = {
  '7Digital': '7digital_001',
  'ACRCloud': 'acrcloud_001',
  'Alibaba': 'alibaba_001',
  'Amazon': 'amazon_001',
  'AMI Entertainment': 'ami_001',
  'Anghami': 'anghami_001',
  'Apple': 'apple_001',
  'Audible Magic': 'audible_magic_001',
  'Audiomack': 'audiomack_001',
  'BMAT': 'bmat_001',
  'Boomplay': 'boomplay_001',
  'Claro': 'claro_001',
  'ClicknClear': 'clicknclear_001',
  'd\'Music': 'dmusic_001',
  'Deezer': 'deezer_001',
  'Meta': 'meta_001',
  'Gracenote': 'gracenote_001',
  'iHeartRadio': 'iheartradio_001',
  'JioSaavn': 'jiosaavn_001',
  'JOOX': 'joox_001',
  'Kan Music': 'kan_music_001',
  'KDM(K Digital Media)': 'kdm_001',
  'KK Box': 'kkbox_001',
  'LiveOne': 'liveone_001',
  'Medianet': 'medianet_001',
  'Mixcloud': 'mixcloud_001',
  'Mood Media': 'mood_media_001',
  'Pandora': 'pandora_001',
  'Peloton': 'peloton_001',
  'Pretzel': 'pretzel_001',
  'Qobuz': 'qobuz_001',
  'Resso': 'resso_001',
  'Soundcloud': 'soundcloud_001',
  'Spotify': 'spotify_001',
  'Tidal': 'tidal_001',
  'TikTok': 'tiktok_001',
  'TouchTunes': 'touchtunes_001',
  'Trebel': 'trebel_001',
  'Tuned Global': 'tuned_global_001',
  'USEA': 'usea_001',
  'VL Group': 'vl_group_001',
  'YouSee': 'yousee_001',
  'YouTube': 'youtube_001',
};

/// ApiService provides Firestore CRUD operations for products and tracks,
/// including batch updates for index syncing.
class ApiService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  ApiService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;

  /// Returns the current user, or throws if not logged in.
  User get currentUser {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'NO_CURRENT_USER',
        message: 'No user is currently signed in.',
      );
    }
    return user;
  }

  /// Create a new product and update the user's product index in a batch.
  /// Throws on error.
  Future<void> createProduct(Product product, IndexEntry indexEntry) async {
    final userId = currentUser.uid;
    final batch = firestore.batch();
    final productRef = firestore.collection('products').doc(product.id);
    final userCatalogRef = firestore.doc('catalog/$userId');
    batch.set(productRef, product.toMap());
    batch.update(userCatalogRef, {
      'allProductsIndex.${product.id}': indexEntry.toMap(),
    });
    await batch.commit();
  }

  /// Update an existing product and its index entry in a batch.
  /// Throws on error.
  Future<void> updateProduct(
    Product product,
    IndexEntry updatedIndexEntry,
  ) async {
    final userId = currentUser.uid;
    final batch = firestore.batch();
    final productRef = firestore.collection('products').doc(product.id);
    final userCatalogRef = firestore.doc('catalog/$userId');
    batch.update(productRef, product.toMap());
    batch.update(userCatalogRef, {
      'allProductsIndex.${product.id}': updatedIndexEntry.toMap(),
    });
    await batch.commit();
  }

  /// Delete a product and remove it from the user's product index in a batch.
  /// Throws on error. Associated tracks/storage should be deleted by a Cloud Function.
  Future<void> deleteProduct(String productId) async {
    final userId = currentUser.uid;
    final batch = firestore.batch();
    final productRef = firestore.collection('products').doc(productId);
    final userCatalogRef = firestore.doc('catalog/$userId');
    batch.delete(productRef);
    batch.update(userCatalogRef, {
      'allProductsIndex.$productId': FieldValue.delete(),
    });
    await batch.commit();
    // Optionally delete associated tracks/storage via Cloud Function
  }

  Future<Product?> getProduct(
    String userId,
    String projectId,
    String productId,
  ) async {
    try {
      final docSnapshot =
          await firestore
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .get();
      if (!docSnapshot.exists) {
        return null;
      }
      final data = docSnapshot.data()!;
      // Product.fromMap expects an id argument, so pass productId explicitly
      return Product.fromMap(data, productId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTracksForProduct(
    String userId,
    String projectId,
    String productId,
  ) async {
    // Validate all path components
    if (userId.isEmpty || projectId.isEmpty || productId.isEmpty) {
      return [];
    }

    try {
      QuerySnapshot<Map<String, dynamic>> trackSnapshot =
          await firestore
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .collection('tracks')
              .orderBy('trackNumber') // Order tracks by track number
              .get();

      final tracks =
          trackSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id; // Add the document ID

            // Ensure track number exists with a default value
            if (!data.containsKey('trackNumber')) {
              data['trackNumber'] = 0;
            }

            return data;
          }).toList();

      return tracks;
    } catch (e) {
      return []; // Return empty list instead of throwing to avoid UI errors
    }
  }

  /// Save a track and update the track count in the product index.
  /// Throws on error.
  Future<void> saveTrack(
    Track track,
    String projectId,
    String productId,
  ) async {
    final userId = currentUser.uid;
    final trackRef = firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .doc(productId)
        .collection('tracks')
        .doc(track.id);
    await trackRef.set(track.toMap());

    final trackCollectionRef = firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .doc(productId)
        .collection('tracks');
    final count = (await trackCollectionRef.get()).docs.length;

    final productRef = firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .doc(productId);
    await productRef.update({
      'trackCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a track and update the track count in the product index.
  /// Throws on error.
  Future<void> deleteTrack(String trackId, String productId) async {
    final trackRef = firestore.collection('tracks').doc(trackId);
    await trackRef.delete();
    final trackCollectionRef = firestore
        .collection('tracks')
        .where('productId', isEqualTo: productId);
    final count = (await trackCollectionRef.count().get()).count;
    final userId = currentUser.uid;
    final userCatalogRef = firestore.doc('catalog/$userId');
    await userCatalogRef.update({
      'allProductsIndex.$productId.trackCount': count,
      'allProductsIndex.$productId.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add a new method for batch-updating multiple tracks
  Future<void> updateMultipleTracks(
    String userId,
    String projectId,
    String productId,
    List<Map<String, dynamic>> tracksData,
  ) async {
    if (tracksData.isEmpty) return;

    try {
      WriteBatch batch = firestore.batch();
      int batchCount = 0;
      int maxBatchSize = 500; // Firestore limit is 500 operations

      for (var trackData in tracksData) {
        if (!trackData.containsKey('id')) {
          //developer.log('Track data missing ID, skipping', name: 'ApiService');
          continue;
        }

        String trackId = trackData['id'];

        // Remove id from the map to avoid saving it as a field
        Map<String, dynamic> dataToSave = Map.from(trackData);
        dataToSave.remove('id');

        // Add timestamp
        dataToSave['updatedAt'] = FieldValue.serverTimestamp();

        DocumentReference<Map<String, dynamic>> trackRef = firestore
            .collection("catalog")
            .doc(userId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(productId)
            .collection('tracks')
            .doc(trackId);

        batch.set(trackRef, dataToSave, SetOptions(merge: true));

        batchCount++;

        // If we're approaching the batch limit, commit this batch and start a new one
        if (batchCount >= maxBatchSize) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      // Update the track count
      await updateProductTrackCount(userId, projectId, productId);
    } catch (e) {
      //developer.log('Error batch updating tracks: $e', name: 'ApiService');
      throw Exception('Failed to update tracks: $e');
    }
  }

  Future<void> updateProductTrackCount(
    String userId,
    String projectId,
    String productId,
  ) async {
    try {
      // Get the count of tracks
      final trackSnapshot =
          await firestore
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .collection('tracks')
              .get();

      // Get reference to the product document
      final productRef = firestore
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId);

      // Check if the product document exists
      final productDoc = await productRef.get();

      if (productDoc.exists) {
        // If product exists, update it
        await productRef.update({'trackCount': trackSnapshot.docs.length});
      } else {
        // If product doesn't exist, create it with basic information
        //developer.log('Product document does not exist, creating it',
        //    name: 'ApiService');
        await productRef.set({
          'id': productId,
          'trackCount': trackSnapshot.docs.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      //print('Error updating track count: $e');
      throw Exception('Failed to update track count');
    }
  }

  /// Stream the user's product index as a list of IndexEntry objects.
  Stream<List<IndexEntry>> streamProducts() {
    final userId = currentUser.uid;
    return firestore.doc('catalog/$userId').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || data['allProductsIndex'] == null) return [];
      final indexMap = Map<String, dynamic>.from(
        data['allProductsIndex'] as Map,
      );
      return indexMap.entries
          .map(
            (e) => IndexEntry.fromMap(e.value as Map<String, dynamic>, e.key),
          )
          .toList();
    });
  }

  // Stream the user's project index as a list of IndexEntry objects.
  Stream<List<IndexEntry>> streamProjects() {
    final userId = currentUser.uid;
    return firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return [];
          return snapshot.docs
              .map((doc) => IndexEntry.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get all projects for the current user (one-time fetch)
  Future<List<IndexEntry>> getProjects() async {
    final userId = currentUser.uid;
    final querySnapshot =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('projects')
            .get();
    return querySnapshot.docs
        .map((doc) => IndexEntry.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Stream the user's project index as a list of Project objects.
  Stream<List<Project>> streamProjectsRaw() {
    final userId = currentUser.uid;
    return firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return [];
          return snapshot.docs
              .map((doc) => Project.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get all projects for the current user (one-time fetch)
  Future<List<Project>> getProjectsRaw() async {
    final userId = currentUser.uid;
    final querySnapshot =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('projects')
            .get();
    return querySnapshot.docs
        .map((doc) => Project.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get a single project by ID for the current user
  Future<Project?> getProjectById(String projectId) async {
    final userId = currentUser.uid;
    final doc =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('projects')
            .doc(projectId)
            .get();
    if (!doc.exists) return null;
    return Project.fromMap(doc.data()!, doc.id);
  }

  // Get all products for a project (by projectId) for the current user
  Future<List<Product>> getProductsByProjectId(String projectId) async {
    final userId = currentUser.uid;
    final querySnapshot =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .get();
    return querySnapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get a single product by ID within a project for the current user
  Future<Product?> getProductById(String projectId, String productId) async {
    final userId = currentUser.uid;
    final doc =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(productId)
            .get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.data()!, doc.id);
  }

  // DELETE PROJECT
  Future<void> deleteProject(String projectId) async {
    try {
      final userId = currentUser.uid;
      await firestore
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // DELETE PRODUCT
  Future<void> deleteProductInProject(
    String projectId,
    String productId,
  ) async {
    try {
      final userId = currentUser.uid;
      await firestore
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Create a new project for the current user.
  Future<void> createProject(Project project) async {
    final userId = currentUser.uid;
    final projectRef = firestore
        .collection('catalog')
        .doc(userId)
        .collection('projects')
        .doc(project.id);
    await projectRef.set(project.toMap());
  }

  /// Update an existing project for the current user.
  Future<void> updateProject(
    String userId,
    String projectId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await firestore
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Fetch all artists with their document IDs for the current user.
  Future<List<Map<String, dynamic>>> fetchAllArtistsWithIds() async {
    final userId = currentUser.uid;
    final snapshot =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('artists')
            .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Fetch all songwriters with their document IDs for the current user.
  Future<List<Map<String, dynamic>>> fetchAllSongwritersWithIds() async {
    final userId = currentUser.uid;
    final snapshot =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('songwriters')
            .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Check if an artist with the given name exists for the current user.
  Future<bool> checkArtistExists(String artistName) async {
    final userId = currentUser.uid;
    final query =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('artists')
            .where('name', isEqualTo: artistName)
            .limit(1)
            .get();
    return query.docs.isNotEmpty;
  }

  /// Create a new artist for the current user.
  Future<void> createArtist(Map<String, dynamic> artistData) async {
    final userId = currentUser.uid;
    await firestore
        .collection('catalog')
        .doc(userId)
        .collection('artists')
        .add(artistData);
  }

  /// Create a new songwriter for the current user.
  Future<void> createSongwriter(Map<String, dynamic> songwriterData) async {
    final userId = currentUser.uid;
    await firestore
        .collection('catalog')
        .doc(userId)
        .collection('songwriters')
        .add(songwriterData);
  }

  /// Get artist profile image by artist ID for the current user.
  Future<String?> getArtistProfileImage(String artistId) async {
    final userId = currentUser.uid;
    final doc =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('artists')
            .doc(artistId)
            .get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['profileImage'] as String?;
  }

  /// Fetch all label documents for the current user.
  Future<List<Map<String, dynamic>>> fetchLabels() async {
    final userId = currentUser.uid;
    final snapshot =
        await firestore
            .collection('catalog')
            .doc(userId)
            .collection('labels')
            .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Get the artist name for a project by userId and projectId.
  Future<String?> getArtistByProjectId(String userId, String projectId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> projectDoc = await firestore
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (projectDoc.exists) {
        var projectData = projectDoc.data();
        return projectData?['projectArtist']?.toString();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String> getAudioUploadPath(
    String userId,
    String projectId,
    String productId,
    String audioUid,
  ) async {
    return 'catalog/$userId/projects/$projectId/products/$productId/tracks/$audioUid';
  }

  Future<void> distributeProduct(
    String userId,
    String projectId,
    String productId,
    List<String> selectedStores,
    DateTime releaseDate,
    TimeOfDay? releaseTime,
    bool useRollingRelease,
    String? timeZone,
  ) async {
    if (userId.isEmpty || projectId.isEmpty || productId.isEmpty) {
      throw Exception('User ID, Project ID, or Product ID is missing');
    }

    try {
      // Get reference to the original product document
      final docRef = firestore
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId);

      // Get current product data
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Product not found');
      }

      Map<String, dynamic> productData = docSnapshot.data()!;

      // Create platform selections with hardcoded IDs
      List<Map<String, String>> platformsSelected =
          selectedStores.map((platform) {
            final platformId = platformIds[platform];
            if (platformId == null) {
              throw Exception('Platform ID not found for: $platform');
            }
            return {'name': platform, 'id': platformId};
          }).toList();

      // Update product data
      productData['state'] = 'Processing';
      productData['platformsSelected'] = platformsSelected;
      productData['releaseDate'] = releaseDate.toIso8601String();

      if (releaseTime != null) {
        productData['releaseTime'] =
            '${releaseTime.hour.toString().padLeft(2, '0')}:${releaseTime.minute.toString().padLeft(2, '0')}';
      }

      productData['useRollingRelease'] = useRollingRelease;
      if (!useRollingRelease && timeZone != null) {
        productData['timeZone'] = timeZone;
      }

      // Add metadata about the original product location
      productData['originalPath'] = {
        'userId': userId,
        'projectId': projectId,
        'productId': productId,
      };

      // Start a batch write
      WriteBatch batch = firestore.batch();

      // Update the original product document
      batch.update(docRef, productData);

      // Create a copy in the private pending collection
      final pendingRef = firestore
          .collection('_private')
          .doc(userId)
          .collection('pending')
          .doc(productId);

      batch.set(pendingRef, productData);

      // Commit both operations
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to distribute product: $e');
    }
  }

  Future<List<String>> fetchAllArtists() async {
    if (auth.currentUser == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.currentUser!.uid;

    try {
      // Fetch all artist documents for the user, ordered by name
      QuerySnapshot<Map<String, dynamic>> artistSnapshot =
          await firestore
              .collection("artists")
              .doc(userId)
              .collection('myArtists')
              .orderBy('name') // Ensure this field is indexed
              .get();

      // Extract artist names from the documents
      List<String> allArtists =
          artistSnapshot.docs
              .map((doc) => doc.data()['name']?.toString() ?? 'Unknown Artist')
              .toList();

      return allArtists;
    } catch (e) {
      //print('Error fetching all artists: $e');
      return [];
    }
  }

  /// Fetches all songwriters for the current user without pagination, ordered by name.
  Future<List<String>> fetchAllSongwriters() async {
    if (auth.currentUser == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.currentUser!.uid;

    try {
      // Fetch all songwriter documents for the user, ordered by name
      QuerySnapshot<Map<String, dynamic>> songwriterSnapshot =
          await firestore
              .collection("songwriters")
              .doc(userId)
              .collection('mySongwriters')
              .orderBy('name') // Ensure this field is indexed
              .get();

      // Extract songwriter names from the documents
      List<String> allSongwriters =
          songwriterSnapshot.docs
              .map(
                (doc) => doc.data()['name']?.toString() ?? 'Unknown Songwriter',
              )
              .toList();

      return allSongwriters;
    } catch (e) {
      //print('Error fetching all songwriters: $e');
      return [];
    }
  }

  Future<List<String>> searchInCollection(
    String collection,
    String query,
  ) async {
    try {
      final db = FirebaseFirestore.instance;
      final results =
          await db
              .collection(collection)
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: '${query}z')
              .limit(10)
              .get();

      return results.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      //developer.log('Error searching in collection: $e', name: 'ApiService');
      return [];
    }
  }
}
