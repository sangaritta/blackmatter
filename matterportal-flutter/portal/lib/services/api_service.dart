import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Models/project.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // Add this import for TimeoutException
import 'dart:developer' as developer; // Import developer for logging
import 'dart:typed_data'; // For Uint8List
import 'dart:math'; // For min function
import 'package:portal/Services/storage_service.dart';
import 'package:universal_html/html.dart' as html;

// Hardcoded platform IDs
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

class ApiService {
  late final FirebaseFirestore db;

  ApiService() {
    // Simply use the existing Firestore instance - NO initialization
    db = FirebaseFirestore.instance;

    // No settings applied here - settings are only applied ONCE in main.dart
  }

  Future<void> saveFcmTokenAndIp(String userId, String fcmToken) async {
    // Get the IP address
    final response = await http.get(Uri.parse('https://api.ipify.org'));
    final ipAddress = response.body;

    // Use direct write instead of reading first, then writing
    await db.collection('users').doc(userId).update({
      'tokens': FieldValue.arrayUnion([
        {'fcmToken': fcmToken, 'ipAddress': ipAddress},
      ]),
    });
  }

  Future<Map<String, dynamic>> getProjects({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 30,
  }) async {
    if (auth.getUser() != null) {
      String userId = auth.getUser()!.uid;

      Query<Map<String, dynamic>> query = db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .orderBy('projectName')
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Add timeout to prevent hanging
      QuerySnapshot<Map<String, dynamic>> projectDocs;
      try {
        projectDocs = await query.get().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Project data loading timed out. Please check your connection and try again.',
            );
          },
        );
      } on TimeoutException catch (e) {
        developer.log('Timeout in getProjects: $e', name: 'ApiService');
        rethrow;
      }

      List<Project> projects =
          projectDocs.docs.map((projectDoc) {
            final projectData = projectDoc.data();
            if (projectData == null) {
              return Project(id: projectDoc.id);
            }
            return Project(
              id: projectDoc.id,
              name: projectData['projectName'] ?? '',
              artist: projectData['projectArtist'] ?? '',
              notes: projectData['notes']?.toString() ?? '',
            );
          }).toList();

      DocumentSnapshot<Map<String, dynamic>>? lastDocument =
          projectDocs.docs.isNotEmpty ? projectDocs.docs.last : null;

      return {'projects': projects, 'lastDocument': lastDocument};
    } else {
      throw Exception('User is not authenticated');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getArtists() async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await db
              .collection("artists")
              .doc(userId)
              .collection('myArtists')
              .get();

      // The document ID will be available in snapshot.docs[index].id
      return snapshot;
    } catch (e) {
      //print('Error fetching artists: $e');
      rethrow;
    }
  }

  DocumentSnapshot<Map<String, dynamic>>? getLastDocumentSnapshot() {
    // This method shouldn't be used anymore - each operation returns its own lastDocument
    developer.log(
      'Warning: getLastDocumentSnapshot() is deprecated. Each pagination operation now returns its own cursor.',
      name: 'ApiService',
    );
    return null;
  }

  Future<void> saveFileReference(
    String? userId,
    String filePath,
    String downloadUrl,
  ) async {
    if (userId == null) return;

    // Use a WriteBatch for batch writes
    WriteBatch batch = db.batch();

    DocumentReference<Map<String, dynamic>> fileRef =
        db.collection('users').doc(userId).collection('files').doc();
    batch.set(fileRef, {
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();
  }

  Future<Map<String, dynamic>> getAllProductsForUser({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfterProject,
  }) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    List<Map<String, dynamic>> allProducts = [];

    Query<Map<String, dynamic>> projectQuery = db
        .collection("catalog")
        .doc(userId)
        .collection('projects')
        .orderBy(FieldPath.documentId) // Ensure consistent ordering
        .limit(limit);

    if (startAfterProject != null) {
      projectQuery = projectQuery.startAfterDocument(startAfterProject);
    }

    // Add timeout to prevent hanging
    QuerySnapshot<Map<String, dynamic>> projectSnapshot;
    try {
      projectSnapshot = await projectQuery.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Product data loading timed out. Please check your connection and try again.',
          );
        },
      );
    } on TimeoutException catch (e) {
      developer.log('Timeout loading products: $e', name: 'ApiService');
      rethrow;
    }

    // Use a batched approach for fetching products
    final futures = projectSnapshot.docs.map((projectDoc) {
      String projectId = projectDoc.id;
      return db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .limit(25) // Limit to prevent excessive reads
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // Return empty QuerySnapshot correctly
              throw TimeoutException('Timeout loading products for project');
            },
          )
          .then((productSnapshot) {
            return productSnapshot.docs.map(
              (productDoc) => {
                ...productDoc.data(),
                'projectId': projectId,
                'documentSnapshot': productDoc,
              },
            );
          })
          .catchError((e) {
            developer.log(
              'Error loading products for project $projectId: $e',
              name: 'ApiService',
            );
            return <Map<String, dynamic>>[];
          });
    });

    try {
      final results = await Future.wait(futures);
      for (var products in results) {
        allProducts.addAll(products);
      }
    } catch (e) {
      developer.log('Error loading products: $e', name: 'ApiService');
    }

    // Return both the products and the last document for pagination
    return {
      'products': allProducts,
      'lastDocument':
          projectSnapshot.docs.isNotEmpty ? projectSnapshot.docs.last : null,
    };
  }

  Future<List<String>> fetchArtists({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
  }) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    Query<Map<String, dynamic>> query = db
        .collection("artists")
        .doc(userId)
        .collection('myArtists')
        .orderBy('name') // Ensure this field is indexed
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot<Map<String, dynamic>> artistDocs = await query.get();

    List<String> artistNames =
        artistDocs.docs
            .map((doc) => doc.data()['name']?.toString() ?? 'Unknown Artist')
            .toList();

    // Don't update any global lastDocument as it doesn't exist anymore
    // Return the last document if needed for pagination elsewhere
    return artistNames;
  }

  Future<Project?> getProjectById(String userId, String projectId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> projectDoc =
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .get();

      if (projectDoc.exists) {
        var projectData = projectDoc.data();
        if (projectData == null) {
          return Project(id: projectDoc.id);
        }
        return Project(
          id: projectDoc.id,
          name: projectData['projectName'] ?? '',
          artist: projectData['projectArtist'] ?? '',
          notes: projectData['notes']?.toString() ?? '',
        );
      } else {
        return null; // Project not found
      }
    } catch (e) {
      // Handle error
      return null;
    }
  }

  Future<String?> getArtistByProjectId(String userId, String projectId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> projectDoc =
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .get();

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

  Future<List<Map<String, dynamic>>> getProductsByProjectId(
    String userId,
    String projectId,
  ) async {
    try {
      QuerySnapshot<Map<String, dynamic>> productDocs =
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .get();

      return productDocs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (!data.containsKey('projectId') || data['projectId'] == null) {
          data['projectId'] = projectId;
        }
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createProject(String userId, Project project) async {
    try {
      DocumentReference<Map<String, dynamic>> projectRef = db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(project.id);

      await projectRef.set({
        'projectName': project.name,
        'projectArtist': project.artist,
        'uid': project.id,
        'notes': project.notes,
        // Add other fields as necessary
      });
    } catch (e) {
      throw Exception('Failed to create project');
    }
  }

  /// Fetches recent artists from the user's recent suggestions.
  Future<List<String>> getRecentArtists() async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    QuerySnapshot<Map<String, dynamic>> recentSnapshot =
        await db
            .collection('artistSuggestions')
            .doc(userId)
            .collection('recent')
            .orderBy('addedAt', descending: true)
            .limit(4)
            .get();

    List<String> recentArtists =
        recentSnapshot.docs
            .map((doc) => doc.data()['artistName']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

    return recentArtists;
  }

  /// Saves a selected artist to the recent suggestions.
  Future<void> saveRecentArtist(String artistName) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    CollectionReference<Map<String, dynamic>> recentCollection = db
        .collection('artistSuggestions')
        .doc(userId)
        .collection('recent');

    // Ensure no duplicates by deleting existing entry
    QuerySnapshot<Map<String, dynamic>> existing =
        await recentCollection.where('artistName', isEqualTo: artistName).get();

    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    // Add the artist to recent with a timestamp
    await recentCollection.add({
      'artistName': artistName,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches all artists for autocomplete suggestions.
  Future<List<String>> fetchArtistsWithSuggestions(String filter) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    // Fetch all artists without pagination
    QuerySnapshot<Map<String, dynamic>> artistSnapshot =
        await db
            .collection("artists")
            .doc(userId)
            .collection('myArtists')
            .orderBy('name') // Ensure this field is indexed
            .get();

    List<String> allArtists =
        artistSnapshot.docs
            .map((doc) => doc.data()['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

    // If a filter is provided, filter the results
    if (filter.isNotEmpty) {
      allArtists =
          allArtists
              .where(
                (name) => name.toLowerCase().contains(filter.toLowerCase()),
              )
              .toList();
    }

    return allArtists;
  }

  /// Fetches all artists for the current user without pagination, ordered by name.
  Future<List<String>> fetchAllArtists() async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    try {
      // Fetch all artist documents for the user, ordered by name
      QuerySnapshot<Map<String, dynamic>> artistSnapshot =
          await db
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
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    try {
      // Fetch all songwriter documents for the user, ordered by name
      QuerySnapshot<Map<String, dynamic>> songwriterSnapshot =
          await db
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

  Future<String> createProduct(
    String userId,
    String projectId,
    Map<String, dynamic> productData,
    String productId,
  ) async {
    if (userId.isEmpty || projectId.isEmpty) {
      throw Exception('User ID or Project ID is missing');
    }
    try {
      final productRef = db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId);

      // Always include the userId field in the product data
      productData['userId'] = userId;
      
      // Save the product with the generated ID
      await productRef.set(productData);

      // Debug log
      return productId; // Return the ID for future use
    } catch (e) {
      // Debug log
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> createArtist(Map<String, dynamic> artistData) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    DocumentReference<Map<String, dynamic>> artistRef =
        db.collection("artists").doc(userId).collection('myArtists').doc();

    await artistRef.set({
      'name': artistData['name'],
      'spotifyUrl': artistData['spotifyUrl'],
      'appleMusicUrl': artistData['appleMusicUrl'],
      'youtubeUrl': artistData['youtubeUrl'],
      'instagramURL': artistData['instagramURL'],
      'facebookUrl': artistData['facebookUrl'],
      'xUrl': artistData['xUrl'],
      'tiktokUrl': artistData['tiktokUrl'],
      'soundcloudUrl': artistData['soundcloudUrl'],
      'imageUrl': artistData['imageUrl'], // Added imageUrl field
    });
  }

  Future<bool> checkArtistExists(String artistName) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    QuerySnapshot<Map<String, dynamic>> artistSnapshot =
        await db
            .collection("artists")
            .doc(userId)
            .collection('myArtists')
            .where('name', isEqualTo: artistName)
            .get();

    return artistSnapshot.docs.isNotEmpty;
  }

  Future<void> updateArtist(
    String artistId,
    Map<String, String> artistData,
  ) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    if (artistId.isEmpty) {
      throw Exception('Invalid artist ID');
    }

    String userId = auth.getUser()!.uid;

    try {
      // Ensure all required fields exist with string values
      final fields = [
        'name',
        'imageUrl',
        'spotifyUrl',
        'appleMusicUrl',
        'youtubeUrl',
        'instagramURL',
        'facebookUrl',
        'xUrl',
        'tiktokUrl',
        'soundcloudUrl',
      ];

      Map<String, String> cleanedData = {};
      for (var field in fields) {
        cleanedData[field] = artistData[field] ?? '';
      }

      await db
          .collection('artists')
          .doc(userId)
          .collection('myArtists')
          .doc(artistId)
          .update(cleanedData);
    } catch (e) {
      //print('Error updating artist: $e');
      throw Exception('Failed to update artist: ${e.toString()}');
    }
  }

  Future<void> deleteArtist(String artistId) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    DocumentReference<Map<String, dynamic>> artistRef = db
        .collection("artists")
        .doc(userId)
        .collection('myArtists')
        .doc(artistId);

    await artistRef.delete();

    // --- UPDATE INDEX: Remove artist from allProductsIndex if needed ---
    // (Implement index update logic if artists are indexed in allProductsIndex)
  }

  Future<void> createSongwriter(Map<String, dynamic> songwriterData) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    DocumentReference<Map<String, dynamic>> songwriterRef =
        db
            .collection("songwriters")
            .doc(userId)
            .collection('mySongwriters')
            .doc();

    await songwriterRef.set({
      'name': songwriterData['name'],
      'email': songwriterData['email'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSongwriter(
    String songwriterId,
    Map<String, dynamic> songwriterData,
  ) async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    if (songwriterId.isEmpty) {
      throw Exception('Invalid songwriter ID');
    }

    String userId = auth.getUser()!.uid;

    try {
      await db
          .collection('songwriters')
          .doc(userId)
          .collection('mySongwriters')
          .doc(songwriterId)
          .update(songwriterData);
    } catch (e) {
      developer.log('Error updating songwriter: $e', name: 'ApiService');
      throw Exception('Failed to update songwriter: ${e.toString()}');
    }
  }

  Future<void> addProductToProject({
    required String userId,
    required String projectId,
    required List<String> artists,
    required String cLine,
    required String coverUrl,
    required String genre,
    required String pLine,
    required Timestamp releaseDate,
    required String state,
    required String subgenre,
    required String title,
    required String type,
    required int upc,
    required String version,
    required String id,
  }) async {
    if (userId.isEmpty || projectId.isEmpty) {
      throw Exception('User ID or Project ID is missing');
    }

    try {
      DocumentReference<Map<String, dynamic>> productRef = db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(id); // Automatically generate a new document ID

      final productData = {
        'artists': artists,
        'cLine': cLine,
        'coverUrl': coverUrl,
        'genre': genre,
        'pLine': pLine,
        'releaseDate': releaseDate,
        'state': state,
        'subgenre': subgenre,
        'title': title,
        'type': type,
        'upc': upc,
        'version': version,
      };

      await productRef.set(productData);
    } catch (e) {
      throw Exception('Failed to add product to project: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProductsForProject(
    String userId,
    String projectId,
  ) async {
    try {
      QuerySnapshot<Map<String, dynamic>> productSnapshot =
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .get();

      // Include the document ID in each product's data
      return productSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Add the document ID
        data['type'] = data['type'] ?? ''; // Ensure type is not null
        if (!data.containsKey('projectId') || data['projectId'] == null) {
          data['projectId'] = projectId;
        }
        return data;
      }).toList();
    } catch (e) {
      // Debug print
      throw Exception('Failed to fetch products for project: $e');
    }
  }

  Future<void> updateProduct(
    String userId,
    String projectId,
    String productId,
    Map<String, dynamic> productData,
  ) async {
    if (userId.isEmpty || projectId.isEmpty || productId.isEmpty) {
      throw Exception('User ID, Project ID, or Product ID is missing');
    }

    try {
      final docRef = db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId);

      // Check if document exists
      final docSnapshot = await docRef.get();

      // Ensure the ID in the data matches the document ID
      productData['id'] = productId;

      if (!docSnapshot.exists) {
        // If document doesn't exist, create it
        await docRef.set(productData);
      } else {
        // If document exists, update it
        await docRef.update(productData);
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> saveTrackReference(
    String userId,
    String projectId,
    String productId,
    String trackId,
    Map<String, dynamic> trackData,
  ) async {
    try {
      developer.log(
        'Starting saveTrackReference for trackId: $trackId',
        name: 'ApiService',
      );

      // Ensure trackNumber exists
      if (!trackData.containsKey('trackNumber')) {
        // Get current track count and use next number
        final trackSnapshot =
            await db
                .collection("catalog")
                .doc(userId)
                .collection('projects')
                .doc(projectId)
                .collection('products')
                .doc(productId)
                .collection('tracks')
                .get();
        trackData['trackNumber'] = trackSnapshot.docs.length + 1;
      }

      // Save the track reference
      await db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('tracks')
          .doc(trackId)
          .set(trackData);

      // Update the track count
      await updateProductTrackCount(userId, projectId, productId);

      developer.log('Successfully saved track reference', name: 'ApiService');
    } catch (e) {
      developer.log('Error saving file reference: $e', name: 'ApiService');
      throw Exception('Failed to save file reference');
    }
  }

  Future<void> saveTrack(
    String userId,
    String projectId,
    String productId,
    String trackId,
    Map<String, dynamic> trackData,
  ) async {
    try {
      developer.log(
        'Starting saveTrack for trackId: $trackId',
        name: 'ApiService',
      );

      // Ensure trackNumber exists
      if (!trackData.containsKey('trackNumber')) {
        // If no track number is provided, get all tracks and determine the next number
        final trackSnapshot =
            await db
                .collection("catalog")
                .doc(userId)
                .collection('projects')
                .doc(projectId)
                .collection('products')
                .doc(productId)
                .collection('tracks')
                .get();

        // Find the maximum track number and add 1
        int maxTrackNumber = 0;
        for (var doc in trackSnapshot.docs) {
          var docData = doc.data();
          if (docData.containsKey('trackNumber')) {
            int trackNum =
                docData['trackNumber'] is int
                    ? docData['trackNumber']
                    : int.tryParse(docData['trackNumber'].toString()) ?? 0;
            if (trackNum > maxTrackNumber) {
              maxTrackNumber = trackNum;
            }
          }
        }

        trackData['trackNumber'] = maxTrackNumber + 1;
      }

      // Get reference to the track document
      final trackRef = db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('tracks')
          .doc(trackId);

      // Check current tracks before saving
      final currentTracks =
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .collection('tracks')
              .get();

      developer.log(
        'Current track count before saving: ${currentTracks.docs.length}',
        name: 'ApiService',
      );

      // First, check if the track already exists
      final existingTrack = await trackRef.get();
      if (existingTrack.exists) {
        developer.log('Track already exists, updating...', name: 'ApiService');
      }

      // Add timestamp to track data
      trackData['updatedAt'] = FieldValue.serverTimestamp();
      trackData['id'] = trackId;

      // Save track data with merge to preserve existing file information
      await trackRef.set(trackData, SetOptions(merge: true));

      // Get the current track count directly after saving
      final trackSnapshot =
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .collection('tracks')
              .get();

      developer.log(
        'Track count after saving: ${trackSnapshot.docs.length}',
        name: 'ApiService',
      );

      // Get reference to the product document
      final productRef = db
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
        developer.log(
          'Product document does not exist, creating it',
          name: 'ApiService',
        );
        await productRef.set({
          'id': productId,
          'trackCount': trackSnapshot.docs.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      developer.log(
        'Successfully updated track count to: ${trackSnapshot.docs.length}',
        name: 'ApiService',
      );
    } catch (e) {
      developer.log('Error saving track: $e', name: 'ApiService');
      throw Exception('Failed to save track: $e');
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
          await db
              .collection("catalog")
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .collection('tracks')
              .get();

      // Get reference to the product document
      final productRef = db
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
        developer.log(
          'Product document does not exist, creating it',
          name: 'ApiService',
        );
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

  Future<void> updateMultipleTracks(
    String userId,
    String projectId,
    String productId,
    List<Map<String, dynamic>> tracksData, {
    void Function(double progress)? onProgress,
  }) async {
    developer.log('updateMultipleTracks called', name: 'ApiService');
    int updated = 0;
    for (final track in tracksData) {
      final trackId = track['id']?.toString() ?? '';
      if (trackId.isNotEmpty) {
        await db
            .collection("catalog")
            .doc(userId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(productId)
            .collection('tracks')
            .doc(trackId)
            .set(track, SetOptions(merge: true));
      }
      updated++;
      if (onProgress != null) {
        onProgress(updated / tracksData.length);
      }
    }
  }

  Future<List<Map<String, dynamic>>> getTracksForProduct(
    String userId,
    String projectId,
    String productId,
  ) async {
    // Validate all path components
    if (userId.isEmpty || projectId.isEmpty || productId.isEmpty) {
      developer.log(
        'Invalid path components - userId: $userId, projectId: $projectId, productId: $productId',
        name: 'ApiService',
      );
      return [];
    }

    try {
      developer.log(
        'Fetching tracks for product - userId: $userId, projectId: $projectId, productId: $productId',
        name: 'ApiService',
      );

      QuerySnapshot<Map<String, dynamic>> trackSnapshot =
          await db
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

      developer.log('Found ${tracks.length} tracks', name: 'ApiService');
      return tracks;
    } catch (e) {
      developer.log('Error fetching tracks: $e', name: 'ApiService');
      return []; // Return empty list instead of throwing to avoid UI errors
    }
  }

  Future<void> deleteTrack(
    String userId,
    String projectId,
    String productId,
    String trackId,
  ) async {
    try {
      // Delete the track document
      await db
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('tracks')
          .doc(trackId)
          .delete();

      // Update the track count
      await updateProductTrackCount(userId, projectId, productId);
    } catch (e) {
      //print('Error deleting track: $e');
      throw Exception('Failed to delete track: $e');
    }
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
      final docRef = db
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
      WriteBatch batch = db.batch();

      // Update the original product document
      batch.update(docRef, productData);

      // Create a copy in the private pending collection
      final pendingRef = db
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

  // Finance Methods
  Future<Map<String, dynamic>> getUserFinancials(String uid) async {
    try {
      final doc = await db.collection('finance').doc(uid).get();
      return doc.data() ??
          {
            'currentBalance': 0.0,
            'monthlyEarnings': 0.0,
            'platformEarnings': {
              'Spotify': 0.0,
              'Apple Music': 0.0,
              'YouTube': 0.0,
              'Others': 0.0,
            },
          };
    } catch (e) {
      //print('Error fetching user financials: $e');
      return {};
    }
  }

  Future<void> updateUserBalance(String uid, double amount) async {
    try {
      await db.collection('finance').doc(uid).set({
        'currentBalance': amount,
      }, SetOptions(merge: true));
    } catch (e) {
      //print('Error updating user balance: $e');
      throw Exception('Failed to update user balance');
    }
  }

  Future<void> updateMonthlyEarnings(String uid, double amount) async {
    try {
      await db.collection('finance').doc(uid).set({
        'monthlyEarnings': amount,
      }, SetOptions(merge: true));
    } catch (e) {
      //print('Error updating monthly earnings: $e');
      throw Exception('Failed to update monthly earnings');
    }
  }

  Future<void> updatePlatformEarnings(
    String uid,
    Map<String, double> platformEarnings,
  ) async {
    try {
      await db.collection('finance').doc(uid).set({
        'platformEarnings': platformEarnings,
      }, SetOptions(merge: true));
    } catch (e) {
      //print('Error updating platform earnings: $e');
      throw Exception('Failed to update platform earnings');
    }
  }

  Future<void> recordEarningsTransaction(
    String uid, {
    required double amount,
    required String platform,
    required String trackId,
    String? description,
  }) async {
    try {
      await db.collection('finance').doc(uid).collection('transactions').add({
        'amount': amount,
        'platform': platform,
        'trackId': trackId,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update total and platform earnings
      final financials = await getUserFinancials(uid);
      final currentBalance = (financials['currentBalance'] ?? 0.0) + amount;
      final platformEarnings = Map<String, double>.from(
        financials['platformEarnings'] ?? {},
      );
      platformEarnings[platform] = (platformEarnings[platform] ?? 0.0) + amount;

      await db.collection('finance').doc(uid).set({
        'currentBalance': currentBalance,
        'platformEarnings': platformEarnings,
      }, SetOptions(merge: true));
    } catch (e) {
      //print('Error recording earnings transaction: $e');
      throw Exception('Failed to record earnings transaction');
    }
  }

  Future<List<Map<String, dynamic>>> getEarningsTransactions(
    String uid, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = db
          .collection('finance')
          .doc(uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshots = await query.get();
      return snapshots.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      //print('Error fetching earnings transactions: $e');
      return [];
    }
  }

  // Songwriter Methods
  Future<QuerySnapshot<Map<String, dynamic>>> getSongwriters() async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }

    String userId = auth.getUser()!.uid;

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await db
              .collection("songwriters")
              .doc(userId)
              .collection('mySongwriters')
              .orderBy('name')
              .get();

      return snapshot;
    } catch (e) {
      throw Exception('Failed to fetch songwriters: $e');
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
      developer.log('Error searching in collection: $e', name: 'ApiService');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await db.collection('users').doc(userId).get();
      return userDoc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProductsBySeller(
    String sellerId,
  ) async {
    final allProductsResult = await getAllProductsForUser();
    final products =
        allProductsResult['products'] as List<Map<String, dynamic>>;
    return products.where((p) => p['sellerId'] == sellerId).toList();
  }

  // STREAM: Get all projects for the current user
  Stream<List<Project>> getProjectsStream() {
    if (auth.getUser() == null) {
      return const Stream.empty();
    }
    final userId = auth.getUser()!.uid;
    print('Fetching projects for user: $userId');
    return db
        .collection("catalog")
        .doc(userId)
        .collection('projects')
        .orderBy('projectName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Project(
                      id: doc.id, // Always use Firestore document ID
                      name: doc.data()['projectName'] ?? '',
                      artist: doc.data()['projectArtist'] ?? '',
                      notes: doc.data()['notes']?.toString() ?? '',
                    ),
                  )
                  .toList(),
        );
  }

  static Project projectFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Project(
      id: doc.id,
      name: data['projectName'] ?? '',
      artist: data['projectArtist'] ?? '',
      notes: data['notes']?.toString() ?? '',
    );
  }

  // STREAM: Get all artists for the current user
  Stream<List<Map<String, dynamic>>> getArtistsStream() {
    if (auth.getUser() == null) {
      return const Stream.empty();
    }
    final userId = auth.getUser()!.uid;
    return db
        .collection('artists')
        .doc(userId)
        .collection('myArtists')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  /// STREAM: Get all songwriters for the authenticated user, sorted by name.
  Stream<List<Map<String, dynamic>>> getSongwritersStream() {
    if (auth.getUser() == null) {
      return const Stream.empty();
    }
    final userId = auth.getUser()!.uid;
    return db
        .collection('songwriters')
        .doc(userId)
        .collection('mySongwriters')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      // Get the current profile to merge with new data
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await db.collection('users').doc(userId).get();

      Map<String, dynamic> currentData = userDoc.data() ?? {};
      Map<String, dynamic> updatedData = {...currentData, ...profileData};

      // Add timestamp for the update
      updatedData['updatedAt'] = FieldValue.serverTimestamp();

      // If this is the first profile update, add a createdAt timestamp
      if (!currentData.containsKey('createdAt')) {
        updatedData['createdAt'] = FieldValue.serverTimestamp();
      }

      await db
          .collection('users')
          .doc(userId)
          .set(updatedData, SetOptions(merge: true));
    } catch (e) {
      developer.log('Error updating user profile: $e', name: 'ApiService');
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<bool> checkProductExistsByUPC(
    String upc, {
    String? indexKey,
    dynamic indexValue,
  }) async {
    final user = auth.getUser();
    if (user == null || upc.isEmpty) {
      return false;
    }
    final userId = user.uid;
    final docSnapshot = await db.collection("catalog").doc(userId).get();
    final data = docSnapshot.data();
    if (data == null) {
      return false;
    }
    return false;
  }

  /// Terminate the user session (sign out and clean up) using sessionId
  Future<void> terminateSession(String sessionId) async {
    try {
      // Optionally: Invalidate or log out the session by sessionId in your backend, if implemented
      // Example: await db.collection('sessions').doc(sessionId).update({'active': false, 'endedAt': DateTime.now()});
      await auth.signOut();
      developer.log(
        'User session terminated for sessionId: $sessionId',
        name: 'ApiService',
      );
    } catch (e) {
      developer.log(
        'Error terminating session for sessionId $sessionId: $e',
        name: 'ApiService',
      );
      throw Exception(
        'Failed to terminate session for sessionId $sessionId: $e',
      );
    }
  }

  /// Restored: Fetch all artists with their IDs (placeholder, implement as needed)
  Future<List<Map<String, dynamic>>> fetchAllArtistsWithIds() async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }
    String userId = auth.getUser()!.uid;
    final snapshot =
        await db
            .collection("artists")
            .doc(userId)
            .collection('myArtists')
            .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Restored: Fetch all songwriters with their IDs (placeholder, implement as needed)
  Future<List<Map<String, dynamic>>> fetchAllSongwritersWithIds() async {
    if (auth.getUser() == null) {
      throw Exception('User is not authenticated');
    }
    String userId = auth.getUser()!.uid;
    final snapshot =
        await db
            .collection("songwriters")
            .doc(userId)
            .collection('mySongwriters')
            .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>?> getProductObject(
    String userId,
    String projectId,
    String productId,
  ) async {
    final doc =
        await db
            .collection("catalog")
            .doc(userId)
            .collection('projects')
            .doc(projectId)
            .collection('products')
            .doc(productId)
            .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        data['id'] = doc.id;
        if (!data.containsKey('projectId') || data['projectId'] == null) {
          data['projectId'] = projectId;
        }
      }
      return data;
    }
    return null;
  }

  /// Restored: Generate a new UPC (placeholder, implement as needed)

  /// Restored: Get user profile (placeholder, implement as needed)
  // Removed duplicate definition

  /// Restored: Returns a formatted location string for a session object.
  String getFormattedLocation(Map<String, dynamic> session) {
    final city = session['city'] ?? '';
    final region = session['region'] ?? '';
    final country = session['country'] ?? '';
    final lat = session['latitude']?.toString() ?? '';
    final lon = session['longitude']?.toString() ?? '';
    String location = '';
    if (city.isNotEmpty) {
      location += city;
    }
    if (region.isNotEmpty) {
      if (location.isNotEmpty) location += ', ';
      location += region;
    }
    if (country.isNotEmpty) {
      if (location.isNotEmpty) location += ', ';
      location += country;
    }
    if (location.isEmpty && lat.isNotEmpty && lon.isNotEmpty) {
      location = '($lat, $lon)';
    }
    if (location.isEmpty) {
      location = 'Unknown Location';
    }
    return location;
  }

  /// Fetches the profile image URL for a given artist name.
  Future<String?> getArtistProfileImage(String artistName) async {
    if (artistName.isEmpty) return null;
    try {
      final user = auth.getUser();
      if (user == null) throw Exception('User is not authenticated');
      final artistDoc =
          await db
              .collection("artists")
              .doc(user.uid)
              .collection('myArtists')
              .where('name', isEqualTo: artistName)
              .limit(1)
              .get();
      if (artistDoc.docs.isNotEmpty) {
        final data = artistDoc.docs.first.data();
        final imageUrl = data['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
        // Optionally, fallback to spotifyUrl logic if needed
        // final spotifyUrl = data['spotifyUrl'] as String?;
        // if (spotifyUrl != null) {
        //   return await MusicVerificationService().getSpotifyArtistImage(spotifyUrl);
        // }
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting artist profile image: $e',
        name: 'ApiService',
      );
      return null;
    }
  }

  /// Fetch all labels for the authenticated user, sorted by name.
  Future<List<Map<String, dynamic>>> fetchLabels() async {
    final user = auth.getUser();
    if (user == null) throw Exception('User is not authenticated');
    try {
      final labelSnapshot =
          await db
              .collection("labels")
              .doc(user.uid)
              .collection('myLabels')
              .orderBy('name')
              .get();
      return labelSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'cLine': data['cLine'] ?? '',
          'pLine': data['pLine'] ?? '',
        };
      }).toList();
    } catch (e) {
      developer.log('Error fetching labels: $e', name: 'ApiService');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProduct(
    String userId,
    String projectId,
    String productId,
  ) async {
    try {
      final doc =
          await db
              .collection('catalog')
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('products')
              .doc(productId)
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          if (!data.containsKey('projectId') || data['projectId'] == null) {
            data['projectId'] = projectId;
          }
          data['id'] = doc.id;
        }
        return data;
      }
      return null;
    } catch (e) {
      developer.log('Error fetching product: $e', name: 'ApiService');
      return null;
    }
  }

  /// Returns the storage path for audio uploads for a given user/project/product/track.
  String getAudioUploadPath(
    String userId,
    String projectId,
    String productId,
    String trackId,
  ) {
    return 'audio_uploads/$userId/$projectId/$productId/$trackId';
  }

  /// Updates a project document for a user.
  Future<void> updateProject(
    String userId,
    String projectId,
    Map<String, dynamic> data,
  ) async {
    try {
      await db
          .collection('catalog')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update(data);
    } catch (e) {
      developer.log('Error updating project: $e', name: 'ApiService');
      rethrow;
    }
  }

  /// Clears the in-memory product cache for the user, or all users if no userId is given.
  void clearProductCache([String? userId]) {
    // Cache logic removed; method is now a no-op for backward compatibility
    developer.log(
      'clearProductCache called, but cache logic has been removed.',
      name: 'ApiService',
    );
  }

  /// Toggle favorite status for an artist
  Future<void> toggleArtistFavorite(String artistId, bool newValue) async {
    final user = auth.getUser();
    if (user == null) return;
    final userId = user.uid;
    await db
        .collection('artists')
        .doc(userId)
        .collection('myArtists')
        .doc(artistId)
        .update({'favorite': newValue});
  }

  /// Stream: Only favorite artists for the authenticated user
  Stream<List<Map<String, dynamic>>> getFavoriteArtistsStream() {
    if (auth.getUser() == null) {
      return const Stream.empty();
    }
    final userId = auth.getUser()!.uid;
    return db
        .collection('artists')
        .doc(userId)
        .collection('myArtists')
        .where('favorite', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  /// STREAM: Get all tracks for a product in real time (Firestore)
  Stream<List<Map<String, dynamic>>> getTracksStream(
    String userId,
    String projectId,
    String productId,
  ) {
    if (userId.isEmpty || projectId.isEmpty || productId.isEmpty) {
      return const Stream.empty();
    }
    return db
        .collection("catalog")
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('products')
        .doc(productId)
        .collection('tracks')
        .orderBy('trackNumber')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                if (!data.containsKey('trackNumber')) {
                  data['trackNumber'] = 0;
                }
                return data;
              }).toList(),
        );
  }

  /// Uploads an audio file and creates a new track in Firestore for the given product.
  Future<void> uploadTrack({
    required String userId,
    required String projectId,
    required String productId,
    required html.File file,
    List<String> primaryArtists = const [],
    String genre = '',
    String artworkUrl = '',
    void Function(double)? onProgress,
  }) async {
    try {
      // 1. Read file bytes using FileReader (universal_html compatible)
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();
      reader.onLoadEnd.listen((event) {
        completer.complete(reader.result as Uint8List);
      });
      reader.readAsArrayBuffer(file);
      final bytes = await completer.future;
      final trackId = generateTrackId();
      final fileName = file.name;
      // 2. Upload WAV to correct catalog path
      final uploadResult = await st.uploadAudioTrackFromBytes(
        bytes,
        userId,
        projectId,
        productId,
        trackId,
        fileName,
        (progress) {
          if (onProgress != null) onProgress(progress);
        },
      );
      final downloadUrl = uploadResult['url'] ?? '';

      // Compose track data
      final Map<String, dynamic> trackData = {
        'title': fileName,
        'primaryArtists': primaryArtists,
        'genre': genre,
        'artworkUrl': artworkUrl,
        'downloadUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'uid': trackId,
        // Add more fields as needed
      };

      // Save the track to Firestore
      await saveTrack(
        userId,
        projectId,
        productId,
        trackId,
        trackData,
      );
    } catch (e) {
      developer.log('Error uploading track: $e', name: 'ApiService');
      rethrow;
    }
  }

  /// Stream all products using Firestore collection group query
  Stream<List<Map<String, dynamic>>> productsStreamCollectionGroup() {
    return db.collectionGroup('products').snapshots().map((query) =>
      query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList()
    );
  }
  
  /// Stream all products belonging to the current user using collection group query with userId filter
  Stream<List<Map<String, dynamic>>> getUserProductsStream() {
    if (auth.getUser() == null) {
      developer.log('No authenticated user found', name: 'ApiService.getUserProductsStream');
      return const Stream.empty();
    }
    
    final userId = auth.getUser()!.uid;
    developer.log('Getting products for user ID: $userId', name: 'ApiService.getUserProductsStream');
    
    return db
        .collectionGroup('products')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((query) {
          developer.log('Query returned ${query.docs.length} products', name: 'ApiService.getUserProductsStream');
          
          // For debugging, log the first few products if any
          if (query.docs.isNotEmpty) {
            for (var i = 0; i < min(3, query.docs.length); i++) {
              final doc = query.docs[i];
              developer.log('Product ${i+1}: ID=${doc.id}, projectId=${doc.data()['projectId'] ?? 'missing'}, userId=${doc.data()['userId'] ?? 'missing'}', 
                  name: 'ApiService.getUserProductsStream');
            }
          }
          
          return query.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['userId'] = userId;
            // Ensure projectId is present
            String? extractedProjectId;
            final pathSegments = doc.reference.path.split('/');
            final projectsIndex = pathSegments.indexOf('projects');
            if (!data.containsKey('projectId') || data['projectId'] == null) {
              if (projectsIndex != -1 && projectsIndex + 1 < pathSegments.length) {
                extractedProjectId = pathSegments[projectsIndex + 1];
                data['projectId'] = extractedProjectId;
              }
            }
            developer.log('[getUserProductsStream] doc.path=${doc.reference.path}, extractedProjectId=$extractedProjectId, finalProjectId=${data['projectId']}', name: 'ApiService.getUserProductsStream');
            return data;
          }).toList();
        });
  }

  String generateTrackId() {
    return db.collection('catalog').doc().id;
  }
}

ApiService api = ApiService();
