import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portal/Models/product.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/spotify_service.dart';

/// Service to handle importing songs from Spotify and other services
class SongImportService {
  final SpotifyService _spotifyService = SpotifyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Import function that supports progress reporting
  Future<List<Project>> importSpotifyAlbums({
    required List<dynamic> selectedAlbums,
    required String userId,
    required Function(String, int, int) onProgress,
  }) async {
    final int totalToImport = selectedAlbums.length;
    int importedCount = 0;
    List<Project> createdProjects = [];

    try {
      // Step 1: Fetch full album details
      List<Map<String, dynamic>> albumsDetails = [];
      for (var album in selectedAlbums) {
        onProgress('Fetching details for "${album['name']}"', importedCount,
            totalToImport);
        final albumDetails = await _spotifyService.getAlbumDetails(album['id']);
        albumsDetails.add(albumDetails);
      }

      // Step 2: Group albums by ISRC to create projects
      List<Project> projects = _spotifyService.groupAlbumsByIsrc(albumsDetails);

      // Step 3: Save each project
      for (var project in projects) {
        onProgress('Importing "${project.name}"', importedCount, totalToImport);
        await _saveProject(project, userId);

        // Count imported products for progress tracking
        importedCount += project.products?.length ?? 1;

        // Add to created projects list
        createdProjects.add(project);
      }

      return createdProjects;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveProject(Project project, String userId) async {
    try {
      // Reference to catalog collection for the user
      final projectsRef =
          _db.collection('catalog').doc(userId).collection('projects');

      // Create a new document with the generated ID
      final docRef = projectsRef.doc(project.id);

      // Prepare project data
      Map<String, dynamic> projectData = {
        'uid': project.id,
        'projectName': project.name,
        'projectArtist': project.artist,
        'notes': project.notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'productCount': project.products?.length ?? 0,
      };

      // Save project
      await docRef.set(projectData);

      // Save products for this project
      if (project.products != null && project.products!.isNotEmpty) {
        for (var product in project.products!) {
          await _saveProduct(product, userId, project.id);
        }
      }
    } catch (e) {
      throw Exception('Failed to save project: $e');
    }
  }

  Future<void> _saveProduct(
      Product product, String userId, String projectId) async {
    try {
      // Use the collection path that matches the Firestore rules
      final productsRef = _db
          .collection('catalog')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products');

      // Create a new document with auto-generated ID
      final docRef = productsRef.doc();
      final productId = docRef.id;

      // Extract year from release date or use current year as fallback
      String releaseYear = DateTime.now().year.toString();
      if (product.releaseDate.isNotEmpty) {
        // Try to extract year from release date (YYYY-MM-DD or YYYY format)
        if (product.releaseDate.length >= 4) {
          releaseYear = product.releaseDate.substring(0, 4);
        }
      }

      // Default platforms for distribution
      List<String> defaultPlatforms = [
        'Spotify',
        'Apple Music',
        'Amazon Music',
        'YouTube Music',
        'Deezer',
        'Tidal',
        'Pandora',
        'TikTok',
        'Instagram',
        'Facebook'
      ];

      // Create platformsSelected array with proper format (includes IDs)
      List<Map<String, String>> platformsSelected = [];
      List<String> platforms = product.platforms ?? defaultPlatforms;

      for (String platform in platforms) {
        // Check if this platform name exists in the platformIds map
        if (platformIds.containsKey(platform)) {
          platformsSelected.add({
            'name': platform,
            'id': platformIds[platform]!,
          });
        }
      }

      // Ensure genre and subgenre are never empty
      String genre = product.genre ?? 'Pop';
      String subgenre = product.subgenre ?? product.genre ?? 'Pop';

      // Attempt to find artist IDs for the primary artists
      List<String> artistIds = [];
      if (product.productArtists.isNotEmpty) {
        try {
          // For each artist name, either find their ID in the database or create a new artist
          for (String artistName in product.productArtists) {
            String artistId = await _getOrCreateArtistId(
                userId, artistName, product.productArtistIds);
            artistIds.add(artistId);
          }
        } catch (e) {
          // In case of error, just use empty IDs
          artistIds = List.filled(product.productArtists.length, '');
        }
      }

      // Prepare product data
      Map<String, dynamic> productData = {
        // Basic identification fields
        'id': productId,
        'productId': productId,
        'uid': productId,

        // Essential product information
        'type': product.type,
        'releaseTitle': product.productName,
        'title': product.productName,
        'releaseVersion': product.releaseVersion ?? '',

        // Artist information
        'primaryArtists': product.productArtists ?? [],
        'artists': product.productArtists ?? [],
        'primaryArtistIds': artistIds, // Use properly mapped artist IDs
        'artistIds': artistIds, // Mirror field for consistency

        // Copyright information - using release year
        'cLine': "© $releaseYear ${product.label ?? 'BlackMatter Studios'}",
        'cLineYear': releaseYear,
        'pLine': "℗ $releaseYear ${product.label ?? 'BlackMatter Studios'}",
        'pLineYear': releaseYear,

        // Additional metadata
        'price': product.price ?? "Album - ${product.type}",
        'label': product.label ?? 'BlackMatter Studios',
        'genre': genre,
        'subgenre': subgenre,
        'metadataLanguage': product.metadataLanguage ?? 'en',

        // Date fields
        'releaseDate': product.releaseDate.length >= 10
            ? product.releaseDate
            : '${product.releaseDate}-01-01',

        // UPC information
        'upc': product.upc.isNotEmpty ? product.upc : 'PENDING',
        'autoGenerateUPC': product.autoGenerateUPC ?? true,

        // URL fields
        'coverImage': product.coverImage,
        'coverUrl': product.coverImage,

        // Status information
        'state': 'Draft',

        // Distribution platforms - Add both formats for compatibility
        'platforms': platforms,
        'platformsSelected': platformsSelected,

        // Project relationship
        'projectId': projectId,
        'userId': userId,

        // System fields
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'trackCount': product.songs.length,

        // Set default rolling release to true for imports
        'useRollingRelease': true,
      };

      // Save product
      await docRef.set(productData);

      // Save tracks for this product
      if (product.songs.isNotEmpty) {
        for (var track in product.songs) {
          await _saveTrack(track, userId, projectId, productId);
        }
      }
    } catch (e) {
      throw Exception('Failed to save product: $e');
    }
  }

  // Helper method to get an artist ID or create a new artist if needed
  Future<String> _getOrCreateArtistId(
      String userId, String artistName, List<String>? spotifyIds) async {
    try {
      // First check if the artist exists by name
      QuerySnapshot<Map<String, dynamic>> artistSnapshot = await _db
          .collection("artists")
          .doc(userId)
          .collection('myArtists')
          .where('name', isEqualTo: artistName)
          .limit(1)
          .get();

      // If artist exists, return its ID
      if (artistSnapshot.docs.isNotEmpty) {
        return artistSnapshot.docs.first.id;
      }

      // If we have a Spotify ID for this artist, try to create from Spotify
      String? spotifyId;
      if (spotifyIds != null && spotifyIds.isNotEmpty) {
        // Find a matching Spotify ID for this artist
        for (String id in spotifyIds) {
          if (id.startsWith('spotify:')) {
            spotifyId = id;
            break;
          }
        }
      }

      if (spotifyId != null) {
        // Create artist from Spotify data
        String newArtistId =
            await _ensureArtistExists(userId, artistName, spotifyId);
        if (newArtistId.isNotEmpty) {
          return newArtistId;
        }
      }

      // If all else fails, create a basic artist entry
      DocumentReference<Map<String, dynamic>> artistRef =
          _db.collection("artists").doc(userId).collection('myArtists').doc();

      await artistRef.set({
        'name': artistName,
        'spotifyUrl': '',
        'appleMusicUrl': '',
        'youtubeUrl': '',
        'instagramURL': '',
        'facebookUrl': '',
        'xUrl': '',
        'tiktokUrl': '',
        'soundcloudUrl': '',
        'imageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return artistRef.id;
    } catch (e) {
      print('Error getting/creating artist: $e');
      return '';
    }
  }

  Future<void> _saveTrack(
      dynamic track, String userId, String projectId, String productId) async {
    try {
      // Use the collection path that matches the Firestore rules
      final tracksRef = _db
          .collection('catalog')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('tracks');

      // Create a new document with auto-generated ID
      final docRef = tracksRef.doc();
      final trackId = docRef.id;

      // Safe way to get filename, handling missing property case
      String fileName;
      try {
        // Try to access fileName property if it exists (will throw if method not found)
        fileName = track.fileName;
      } catch (e) {
        // If fileName property doesn't exist or throws error, generate from title
        String sanitizedTitle =
            track.title.toString().replaceAll(RegExp(r'[^\w\s.-]'), '_');
        fileName = "$sanitizedTitle.wav";
      }

      // Build storage path
      String storagePath =
          "catalog/$userId/projects/$projectId/products/$productId/tracks/${trackId}_$fileName";

      // Find artist IDs for track artists
      List<String> primaryArtistIds = [];
      List<String> featuredArtistIds = [];

      try {
        if (track.primaryArtists != null && track.primaryArtists.isNotEmpty) {
          // For each primary artist, get or create an artist ID
          for (String artistName in track.primaryArtists) {
            String artistId = await _getOrCreateArtistId(
                userId, artistName, track.primaryArtistIds);
            primaryArtistIds.add(artistId);
          }

          // Match featured artists if present
          if (track.featuredArtists != null &&
              track.featuredArtists.isNotEmpty) {
            for (String artistName in track.featuredArtists) {
              String artistId = await _getOrCreateArtistId(
                  userId, artistName, track.featuredArtistIds);
              featuredArtistIds.add(artistId);
            }
          }
        }
      } catch (e) {
        // In case of error, initialize with empty IDs
        primaryArtistIds = List.filled(track.primaryArtists?.length ?? 0, '');
        featuredArtistIds = List.filled(track.featuredArtists?.length ?? 0, '');
      }

      // Ensure genre is never empty
      String genre = track.genre ?? 'Pop';

      // When creating Track objects, ensure trackNumber is provided
      // If the track object already has a trackNumber property, use it
      // Otherwise, provide a default value
      int trackNumber = 0;
      try {
        trackNumber = track.trackNumber ?? 0;
      } catch (e) {
        // If trackNumber can't be accessed, use default value
      }

      // Prepare track data to match expected format
      Map<String, dynamic> trackData = {
        'id': trackId,
        'trackId': trackId,
        'title': track.title,
        'fileName': fileName,
        'version': track.version ?? '',
        'isExplicit': track.isExplicit ?? false,

        // Artists information
        'primaryArtists': track.primaryArtists ?? [],
        'primaryArtistIds': primaryArtistIds,
        'featuredArtists': track.featuredArtists ?? [],
        'featuredArtistIds': featuredArtistIds,

        // Location information
        'country': track.country ?? 'CR',
        'nationality': track.nationality ?? 'CR',

        // Track identification
        'isrcCode': track.isrc ?? 'AUTO',
        'isrc': track.isrc ?? 'AUTO',

        // Ownership
        'ownership': track.ownership ?? 'Original',

        // Contributors with roles
        'performers': track.performersWithRoles
                ?.map((performer) => {
                      'name': performer.name,
                      'roles': performer.roles ?? ['Actor']
                    })
                .toList() ??
            [],

        'songwriters': track.songwritersWithRoles
                ?.map((songwriter) => {
                      'name': songwriter.name,
                      'roles': songwriter.roles ?? ['Lyricist']
                    })
                .toList() ??
            [],

        'production': track.productionWithRoles
                ?.map((producer) => {
                      'name': producer.name,
                      'roles': producer.roles ?? ['Vocal Engineer']
                    })
                .toList() ??
            [],

        // File storage and URLs
        'storagePath': storagePath,
        'artworkUrl': track.artworkUrl ?? '',
        'downloadUrl': track.downloadUrl ?? '',

        // Additional metadata
        'genre': genre,
        'lyrics': track.lyrics ?? '',
        'syncedLyrics': track.syncedLyrics ?? {},

        // System fields
        'uid': trackId,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'trackNumber': trackNumber,
      };

      // Save track
      await docRef.set(trackData);
    } catch (e) {
      throw Exception('Failed to save track: $e');
    }
  }

  /// Checks if an artist with the given Spotify URL exists, and creates one if not
  Future<String> _ensureArtistExists(
      String userId, String artistName, String spotifyArtistId) async {
    try {
      // Skip if the ID doesn't start with spotify:
      if (!spotifyArtistId.startsWith('spotify:')) {
        return '';
      }

      // Extract clean ID (remove 'spotify:' prefix)
      final spotifyId = spotifyArtistId.substring(8);
      final spotifyUrl = _spotifyService.formatSpotifyArtistUrl(spotifyId);

      // Check if the artist already exists by Spotify URL
      QuerySnapshot<Map<String, dynamic>> existingArtists = await _db
          .collection('artists')
          .doc(userId)
          .collection('myArtists')
          .where('spotifyUrl', isEqualTo: spotifyUrl)
          .limit(1)
          .get();

      // If the artist already exists, return its ID
      if (existingArtists.docs.isNotEmpty) {
        return existingArtists.docs.first.id;
      }

      // Artist doesn't exist, get details from Spotify
      Map<String, String> artistDetails =
          await _spotifyService.getArtistDetails(spotifyId);

      // If we couldn't get details from Spotify, use minimal data
      if (artistDetails['name']!.isEmpty) {
        artistDetails = {
          'name': artistName,
          'spotifyUrl': spotifyUrl,
          'imageUrl': '',
        };
      }

      // Create a new artist document with the Spotify URL
      DocumentReference<Map<String, dynamic>> artistRef =
          _db.collection('artists').doc(userId).collection('myArtists').doc();

      await artistRef.set({
        'name': artistDetails['name'] ?? artistName,
        'spotifyUrl': spotifyUrl,
        'appleMusicUrl': '',
        'youtubeUrl': '',
        'instagramURL': '',
        'facebookUrl': '',
        'xUrl': '',
        'tiktokUrl': '',
        'soundcloudUrl': '',
        'imageUrl': artistDetails['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
          'Created new artist: ${artistDetails['name']} with Spotify URL: $spotifyUrl');
      return artistRef.id;
    } catch (e) {
      print('Error ensuring artist exists: $e');
      return '';
    }
  }
}
