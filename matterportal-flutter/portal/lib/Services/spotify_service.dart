import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:portal/Models/track.dart';
import 'package:portal/Models/product.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Services/auth_service.dart';

class SpotifyService {
  // Using the existing client credentials from the music_verification_service
  static const String _spotifyClientId = '0417a39abe1d401bbf75166b9a695013';
  static const String _spotifyClientSecret = 'e082c66c2f06421089478d7ea101c6b1';

  // Default values for metadata that can't be obtained from APIs
  static const String defaultCline = "© 2024 BlackMatter Portal";
  static const String defaultPline = "℗ 2024 BlackMatter Portal";
  static const String defaultLabel = "BlackMatter Portal";

  Future<String> _getAccessToken() async {
    final tokenResponse = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_spotifyClientId:$_spotifyClientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    final tokenData = json.decode(tokenResponse.body);
    return tokenData['access_token'];
  }

  Future<String> getAccessToken() async {
    return await _getAccessToken();
  }

  Future<Map<String, dynamic>> searchArtist(String artistName) async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse(
        'https://api.spotify.com/v1/search?q=$artistName&type=artist&limit=5',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to search for artist: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getArtistAlbums(String artistId) async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse(
        'https://api.spotify.com/v1/artists/$artistId/albums?include_groups=album,single,compilation&limit=50',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get artist albums: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getArtistById(String artistId) async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get artist details: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getAlbumDetails(String albumId) async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/$albumId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get album details: ${response.body}');
    }
  }

  // Enhanced method to convert Spotify album data with more complete metadata
  Product convertToProduct(Map<String, dynamic> albumData) {
    final tracksData = albumData['tracks']['items'] as List;
    final releaseDate = albumData['release_date'] ?? '';
    final albumType = albumData['album_type'] ?? 'album';
    final releaseYear =
        releaseDate.isNotEmpty
            ? releaseDate.split('-')[0]
            : DateTime.now().year.toString();

    List<String> artists = [];
    List<String> artistIds = []; // List for artist IDs

    if (albumData['artists'] != null) {
      for (var artist in albumData['artists']) {
        artists.add(artist['name']);
        // Store just the Spotify ID without prefix to simplify handling
        artistIds.add('spotify:${artist['id']}');
      }
    }

    String coverImage = '';
    if (albumData['images'] != null &&
        (albumData['images'] as List).isNotEmpty) {
      coverImage = albumData['images'][0]['url'];
    }

    String label = albumData['label'] ?? defaultLabel;

    // Generate UPC if not present
    String upc = albumData['external_ids']?['upc'] ?? '';
    bool autoGenerateUPC = upc.isEmpty;

    // Create standardized copyright lines
    String cLine = "© $releaseYear $label";
    String pLine = "℗ $releaseYear $label";

    // Create Track objects from the album's tracks with your Track model structure
    List<Track> tracks =
        tracksData.map<Track>((trackData) {
          List<String> primaryArtists = [];
          List<String> primaryArtistIds = []; // List for track artist IDs

          for (var artist in trackData['artists']) {
            primaryArtists.add(artist['name']);
            primaryArtistIds.add('spotify:${artist['id']}');
          }

          // Extract featuring artists (those not in primary artists)
          List<String>? featuredArtists;
          List<String>? featuredArtistIds;

          if (trackData['artists'].length > 1) {
            // Consider artists beyond the first one as featuring
            featuredArtists = [];
            featuredArtistIds = [];

            for (var i = 1; i < trackData['artists'].length; i++) {
              featuredArtists.add(trackData['artists'][i]['name']);
              featuredArtistIds.add('spotify:${trackData['artists'][i]['id']}');
            }
          }

          String isrc = '';
          if (trackData['external_ids'] != null &&
              trackData['external_ids']['isrc'] != null) {
            isrc = trackData['external_ids']['isrc'];
          }

          return Track(
            trackNumber:
                trackData['track_number'] ??
                0, // Add track number from Spotify data
            title: trackData['name'] ?? '',
            version: null,
            isExplicit: trackData['explicit'] ?? false,
            primaryArtists: primaryArtists,
            primaryArtistIds: primaryArtistIds, // Add artist IDs
            featuredArtists: featuredArtists,
            featuredArtistIds: featuredArtistIds, // Add featured artist IDs
            genre: 'Pop', // Ensure genre is never empty
            performersWithRoles:
                [], // These would need to be populated from another source
            songwritersWithRoles:
                [], // These would need to be populated from another source
            productionWithRoles:
                [], // These would need to be populated from another source
            isrc: isrc,
            uid: trackData['id'] ?? '',
            artworkUrl: coverImage,
            downloadUrl: trackData['preview_url'] ?? '',
          );
        }).toList();

    // Create a properly formatted release date in ISO format
    String formattedReleaseDate = '';
    try {
      final DateTime parsedDate = DateTime.parse(
        releaseDate.length >= 10 ? releaseDate : '$releaseDate-01-01',
      );
      formattedReleaseDate = parsedDate.toIso8601String();
    } catch (e) {
      // Fallback to current date + 1 month
      final nextMonth = DateTime.now().add(const Duration(days: 30));
      formattedReleaseDate = nextMonth.toIso8601String();
    }

    // Determine most appropriate genre and subgenre
    String genre = 'Pop'; // Default genre
    String subgenre = 'Pop'; // Ensure subgenre is never empty

    // If possible, get genre from the artist data
    if (albumData['artists'] != null && albumData['artists'].isNotEmpty) {
      try {
        final artistId = albumData['artists'][0]['id'];
        _fetchArtistGenres(artistId)
            .then((genres) {
              if (genres.isNotEmpty) {
                genre = _mapToStandardGenre(genres[0]);
                if (genres.length > 1) {
                  subgenre = genres[1];
                } else {
                  subgenre = genre; // Fall back to genre if no subgenre
                }
              }
            })
            .catchError((_) {
              // Silently fail if we can't fetch genres
            });
      } catch (e) {
        // Continue with default genre if artist genre fetch fails
      }
    }

    // Create default platformsSelected with the standard format
    List<Map<String, String>> platformsSelected = [
      {'name': 'Spotify', 'id': 'spotify_001'},
      {'name': 'Apple Music', 'id': 'apple_001'},
      {'name': 'YouTube', 'id': 'youtube_001'},
      {'name': 'Amazon Music', 'id': 'amazon_001'},
      {'name': 'Deezer', 'id': 'deezer_001'},
      {'name': 'TikTok', 'id': 'tiktok_001'},
    ];

    return Product(
      userId: auth.getUser()!.uid,
      type: _mapAlbumTypeToProductType(albumType, tracks.length),
      productName: albumData['name'] ?? '',
      productArtists: artists,
      productArtistIds: artistIds, // Add artist IDs
      cLine: cLine,
      pLine: pLine,
      price: _determinePriceFromType(albumType, tracks.length),
      label: label,
      releaseDate: formattedReleaseDate,
      upc: upc,
      uid: albumData['id'] ?? '',
      songs: tracks,
      coverImage: coverImage,
      state: 'Draft',
      // Additional fields that were missing before:
      cLineYear: releaseYear,
      pLineYear: releaseYear,
      autoGenerateUPC: autoGenerateUPC,
      metadataLanguage: _determineLanguageFromText(albumData['name'] ?? ''),
      releaseTitle: albumData['name'] ?? '',
      releaseVersion: '',
      genre: genre,
      subgenre: subgenre,
      useRollingRelease: true,
      releaseTime: '19:00', // Default release time of 7 PM
      artworkUrl: coverImage,
      platformsSelected:
          platformsSelected, // Add platformsSelected field to match expected structure
    );
  }

  // Helper methods for improved metadata

  // Fetch an artist's genres from Spotify
  Future<List<String>> _fetchArtistGenres(String artistId) async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['genres'] ?? []);
    }

    return [];
  }

  // Map Spotify's detailed genres to standard music industry genres
  String _mapToStandardGenre(String spotifyGenre) {
    final genreMap = {
      'hip hop': 'Hip-Hop',
      'rap': 'Hip-Hop',
      'trap': 'Hip-Hop',
      'r&b': 'R&B/Soul',
      'soul': 'R&B/Soul',
      'pop': 'Pop',
      'rock': 'Rock',
      'metal': 'Metal',
      'punk': 'Rock',
      'country': 'Country',
      'folk': 'Folk',
      'jazz': 'Jazz',
      'blues': 'Blues',
      'electronic': 'Electronic',
      'dance': 'Electronic',
      'edm': 'Electronic',
      'house': 'Electronic',
      'techno': 'Electronic',
      'classical': 'Classical',
      'latin': 'Latin',
      'reggae': 'Reggae',
      'reggaeton': 'Latin',
      'world': 'World',
      'indie': 'Alternative',
      'alternative': 'Alternative',
      'ambient': 'New Age',
      'soundtrack': 'Soundtrack',
      'gospel': 'Religious',
      'christian': 'Religious',
    };

    // Find the first matching genre key
    for (var key in genreMap.keys) {
      if (spotifyGenre.toLowerCase().contains(key)) {
        return genreMap[key]!;
      }
    }

    // Default genre if no match found
    return 'Pop';
  }

  // Determine pricing tier from album type and track count
  String _determinePriceFromType(String albumType, int trackCount) {
    switch (albumType.toLowerCase()) {
      case 'single':
        return trackCount <= 1 ? 'Single - Front' : 'Single - Bundle';
      case 'ep':
        return 'EP';
      case 'album':
        return 'Album';
      default:
        return trackCount <= 1
            ? 'Single - Front'
            : (trackCount <= 5 ? 'Single - Bundle' : 'Album');
    }
  }

  // Map Spotify album types to product types
  String _mapAlbumTypeToProductType(String albumType, int trackCount) {
    switch (albumType.toLowerCase()) {
      case 'single':
        return 'Single';
      case 'ep':
        return 'EP';
      case 'album':
        return 'Album';
      case 'compilation':
        return 'Compilation';
      default:
        // If not specified, determine by track count
        if (trackCount <= 3) {
          return 'Single';
        } else if (trackCount <= 6) {
          return 'EP';
        } else {
          return 'Album';
        }
    }
  }

  // Basic language detection based on text content
  String _determineLanguageFromText(String text) {
    // Simple heuristic - detect Spanish by checking for common Spanish characters
    bool hasSpanishChars =
        text.contains('ñ') ||
        text.contains('á') ||
        text.contains('é') ||
        text.contains('í') ||
        text.contains('ó') ||
        text.contains('ú') ||
        text.contains('¿') ||
        text.contains('¡');

    if (hasSpanishChars) {
      return 'es';
    }

    // Default to English
    return 'en';
  }

  // Group albums by ISRC codes to create proper projects
  List<Project> groupAlbumsByIsrc(List<Map<String, dynamic>> albumsData) {
    // Maps to track ISRC codes and group albums
    Map<String, Project> projects = {};
    Map<String, String> isrcToProjectId = {};
    Map<String, DateTime> projectReleaseDate = {};
    Map<String, Map<String, dynamic>> projectLatestAlbum = {};

    // First pass: Create one project per album, and map ISRCs
    for (var albumData in albumsData) {
      Product product = convertToProduct(albumData);

      // Generate a new project ID
      String projectId =
          'SPT${DateTime.now().millisecondsSinceEpoch}_${albumData['id']}';

      // By default, each album gets its own project with the same name as the album
      Project project = Project(
        id: projectId,
        name: albumData['name'] ?? '', // Project name = Album name
        artist:
            product.productArtists.isNotEmpty ? product.productArtists[0] : '',
        notes:
            'Imported from Spotify on ${DateTime.now().toString().split(' ')[0]}',
        products: [product],
      );

      // Store release date for determining the latest release
      DateTime releaseDate = DateTime.parse(
        product.releaseDate.length >= 10
            ? product.releaseDate
            : '${product.releaseDate}-01-01',
      ); // Handle year-only dates

      projectReleaseDate[projectId] = releaseDate;
      projectLatestAlbum[projectId] = albumData;

      // Add project to the collection
      projects[projectId] = project;

      // Track ISRCs for all tracks in this album
      for (var track in product.songs) {
        if (track.isrc.isNotEmpty) {
          // If this ISRC already exists in another project, we need to merge them
          if (isrcToProjectId.containsKey(track.isrc)) {
            String existingProjectId = isrcToProjectId[track.isrc]!;

            // Skip if it's the same project
            if (existingProjectId == projectId) continue;

            // Compare release dates to determine which album is newer
            DateTime existingReleaseDate =
                projectReleaseDate[existingProjectId]!;
            DateTime currentReleaseDate = releaseDate;

            // Merge the projects
            String targetProjectId;
            String sourceProjectId;

            // Use the newer release's project as the target
            if (currentReleaseDate.isAfter(existingReleaseDate)) {
              targetProjectId = projectId;
              sourceProjectId = existingProjectId;
            } else {
              targetProjectId = existingProjectId;
              sourceProjectId = projectId;
            }

            // Move products from source to target
            Project targetProject = projects[targetProjectId]!;
            Project sourceProject = projects[sourceProjectId]!;

            // Add all products from source project to target project
            targetProject.products!.addAll(sourceProject.products!);

            // Update project name to the latest release name
            if (currentReleaseDate.isAfter(existingReleaseDate)) {
              targetProject.name = albumData['name'] ?? '';
              projectLatestAlbum[targetProjectId] = albumData;
            }

            // Update all ISRCs to point to the target project
            for (var product in sourceProject.products!) {
              for (var t in product.songs) {
                if (t.isrc.isNotEmpty) {
                  isrcToProjectId[t.isrc] = targetProjectId;
                }
              }
            }

            // Mark the source project for removal
            projects.remove(sourceProjectId);
            projectReleaseDate.remove(sourceProjectId);
            projectLatestAlbum.remove(sourceProjectId);

            // Update the current project ID if it was merged into an existing one
            if (projectId == sourceProjectId) {
              projectId = targetProjectId;
            }
          } else {
            // Register this ISRC with the current project
            isrcToProjectId[track.isrc] = projectId;
          }
        }
      }
    }

    // Return the list of projects
    return projects.values.toList();
  }

  // Convert a Spotify album to a Project containing the album as a Product
  Project convertToProject(Map<String, dynamic> albumData) {
    Product product = convertToProduct(albumData);

    // Use the album name for the project name (same name for product and project)
    String albumName = albumData['name'] ?? '';

    String artistName = '';
    if (albumData['artists'] != null &&
        (albumData['artists'] as List).isNotEmpty) {
      artistName = albumData['artists'][0]['name'];
    }

    return Project(
      id: 'SPT${DateTime.now().millisecondsSinceEpoch}',
      name: albumName, // Use album name for project
      artist: artistName,
      notes:
          'Imported from Spotify on ${DateTime.now().toString().split(' ')[0]}',
      products: [product],
    );
  }

  /// Formats a Spotify artist URL from an artist ID
  String formatSpotifyArtistUrl(String artistId) {
    // Remove any 'spotify:' prefix if present
    final cleanId =
        artistId.startsWith('spotify:') ? artistId.substring(8) : artistId;

    return 'https://open.spotify.com/artist/$cleanId';
  }

  /// Extracts artist information including image and Spotify URL
  Future<Map<String, String>> getArtistDetails(String artistId) async {
    try {
      final accessToken = await _getAccessToken();

      // Remove any 'spotify:' prefix if present
      final cleanId =
          artistId.startsWith('spotify:') ? artistId.substring(8) : artistId;

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/artists/$cleanId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract image URL (use the largest available)
        String imageUrl = '';
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          // Sort by size (largest first) and take the first one
          final sortedImages = List.from(data['images'])
            ..sort((a, b) => (b['width'] as int).compareTo(a['width'] as int));
          imageUrl = sortedImages.first['url'];
        }

        return {
          'name': data['name'] ?? '',
          'spotifyUrl': 'https://open.spotify.com/artist/$cleanId',
          'imageUrl': imageUrl,
        };
      }
    } catch (e) {
      // Use a more appropriate error handling approach
      // Consider logging this error instead of printing
    }

    return {
      'name': '',
      'spotifyUrl': 'https://open.spotify.com/artist/$artistId',
      'imageUrl': '',
    };
  }
}
