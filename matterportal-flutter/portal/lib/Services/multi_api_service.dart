import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal/Models/product.dart';
import 'package:portal/Models/track.dart';
import 'package:portal/Services/spotify_service.dart';
import 'dart:developer' as developer;

/// Service that aggregates metadata from multiple music APIs to enrich
/// product and track information.
class MultiApiService {
  final SpotifyService _spotifyService = SpotifyService();

  // Last.fm API key - real credentials
  static const String _lastFmApiKey = '791affdfb6b53998013a1dcd5aa6181b';

  // Discogs API token - real credentials
  static const String _discogsConsumerKey = 'PCDESSxAEKmJRFDjBIPU';
  static const String _discogsConsumerSecret =
      'LydkHksYFSwVmpYmAmHcUSFvDiizPRaw';

  // MusicBrainz API - no token needed but should add proper User-Agent
  static const String _musicBrainzUserAgent =
      'Portal/1.0 (https://blackmatter.cc)';

  // Default metadata language if can't be determined
  static const String defaultMetadataLanguage = 'en';

  /// Enriches a product with metadata from multiple sources
  Future<Product> enrichProduct(Product product) async {
    // Start with any Spotify data we can find
    Product enrichedProduct = product;

    try {
      // Try to find the release on Spotify by name & artist
      String artistQuery =
          product.productArtists.isNotEmpty ? product.productArtists[0] : '';
      String titleQuery = product.productName;

      if (artistQuery.isNotEmpty && titleQuery.isNotEmpty) {
        final searchQuery = 'album:$titleQuery artist:$artistQuery';
        final searchResults = await _searchSpotify(searchQuery);

        if (searchResults.isNotEmpty) {
          final albumId = searchResults[0]['id'];
          final albumDetails = await _spotifyService.getAlbumDetails(albumId);

          // Create a temporary enriched product from Spotify
          Product spotifyProduct =
              _spotifyService.convertToProduct(albumDetails);

          // Merge the Spotify data with our existing product data
          enrichedProduct = _mergeProductData(product, spotifyProduct);
        }
      }
    } catch (e) {
      developer.log('Error enriching product with Spotify: $e');
    }

    // Try Discogs for additional data
    try {
      String releaseTitle = product.productName;
      String artistName =
          product.productArtists.isNotEmpty ? product.productArtists[0] : '';

      if (releaseTitle.isNotEmpty && artistName.isNotEmpty) {
        final discogsData = await _searchDiscogs(releaseTitle, artistName);

        if (discogsData != null &&
            discogsData['results'] != null &&
            (discogsData['results'] as List).isNotEmpty) {
          final release = discogsData['results'][0];

          // Get release details if we have a Discogs ID
          if (release['id'] != null) {
            final releaseDetails =
                await _getDiscogsReleaseDetails(release['id'].toString());

            if (releaseDetails != null) {
              // Extract label information
              if (releaseDetails['labels'] != null &&
                  (releaseDetails['labels'] as List).isNotEmpty) {
                String labelName = releaseDetails['labels'][0]['name'];

                if (enrichedProduct.label == "BlackMatter Portal") {
                  enrichedProduct.label = labelName;

                  // Update p-line and c-line with the correct label
                  String year = enrichedProduct.pLineYear.isEmpty
                      ? (releaseDetails['year']?.toString() ??
                          DateTime.now().year.toString())
                      : enrichedProduct.pLineYear;

                  enrichedProduct.pLine = "℗ $year $labelName";
                  enrichedProduct.cLine = "© $year $labelName";
                  enrichedProduct.pLineYear = year;
                  enrichedProduct.cLineYear = year;
                }
              }

              // Extract genre and style information
              if (releaseDetails['genres'] != null &&
                  (releaseDetails['genres'] as List).isNotEmpty) {
                if (enrichedProduct.genre.isEmpty) {
                  enrichedProduct.genre = releaseDetails['genres'][0];
                }
              }

              if (releaseDetails['styles'] != null &&
                  (releaseDetails['styles'] as List).isNotEmpty) {
                if (enrichedProduct.subgenre.isEmpty) {
                  enrichedProduct.subgenre = releaseDetails['styles'][0];
                }
              }

              // Get country information
              if (releaseDetails['country'] != null &&
                  enrichedProduct.country.isEmpty) {
                enrichedProduct.country = releaseDetails['country'];
              }

              // Get tracklist information for enriching individual tracks later
              if (releaseDetails['tracklist'] != null) {
                // We'll use this when enriching individual tracks
              }
            }
          }

          // Get artwork if available
          if (enrichedProduct.coverImage.isEmpty &&
              release['cover_image'] != null) {
            enrichedProduct.coverImage = release['cover_image'];
            enrichedProduct.artworkUrl = release['cover_image'];
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching product with Discogs: $e');
    }

    // Try MusicBrainz for additional data
    try {
      String releaseTitle = product.productName;
      String artistName =
          product.productArtists.isNotEmpty ? product.productArtists[0] : '';

      if (releaseTitle.isNotEmpty && artistName.isNotEmpty) {
        final mbData = await _searchMusicBrainz(releaseTitle, artistName);

        if (mbData != null &&
            mbData['releases'] != null &&
            (mbData['releases'] as List).isNotEmpty) {
          final release = mbData['releases'][0];

          // Extract data from MusicBrainz
          if (enrichedProduct.upc.isEmpty && release['barcode'] != null) {
            enrichedProduct.upc = release['barcode'];
            enrichedProduct.autoGenerateUPC = enrichedProduct.upc.isEmpty;
          }

          // Get additional data if we have a release ID
          if (release['id'] != null) {
            final releaseDetails =
                await _getMusicBrainzReleaseDetails(release['id']);

            if (releaseDetails != null) {
              // Extract country information
              if (releaseDetails['country'] != null) {
                enrichedProduct.country = releaseDetails['country'];
              }

              // Extract label information
              if (releaseDetails['label-info'] != null &&
                  (releaseDetails['label-info'] as List).isNotEmpty &&
                  releaseDetails['label-info'][0]['label'] != null &&
                  releaseDetails['label-info'][0]['label']['name'] != null) {
                String labelName =
                    releaseDetails['label-info'][0]['label']['name'];

                if (enrichedProduct.label == "BlackMatter Portal") {
                  enrichedProduct.label = labelName;

                  // Update p-line and c-line with the correct label
                  String year = enrichedProduct.pLineYear;
                  enrichedProduct.pLine = "℗ $year $labelName";
                  enrichedProduct.cLine = "© $year $labelName";
                }
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching product with MusicBrainz: $e');
    }

    // Try Last.fm for additional data like tags (can help with genre)
    try {
      String albumTitle = product.productName;
      String artistName =
          product.productArtists.isNotEmpty ? product.productArtists[0] : '';

      if (albumTitle.isNotEmpty && artistName.isNotEmpty) {
        final lastFmData = await _getLastFmAlbumInfo(artistName, albumTitle);

        if (lastFmData != null && lastFmData['album'] != null) {
          final album = lastFmData['album'];

          // Get genre/tags if available
          if (album['tags'] != null && album['tags']['tag'] != null) {
            final tags = album['tags']['tag'] as List;
            if (tags.isNotEmpty && enrichedProduct.genre.isEmpty) {
              // Map Last.fm tags to a standard genre
              final tagName = tags[0]['name'].toString().toLowerCase();
              enrichedProduct.genre = _mapLastFmTagToGenre(tagName);

              // If we have more than one tag, use the second as subgenre
              if (tags.length > 1 && enrichedProduct.subgenre.isEmpty) {
                enrichedProduct.subgenre = tags[1]['name'];
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching product with Last.fm: $e');
    }

    // Add default values for still-missing fields
    if (enrichedProduct.metadataLanguage.isEmpty) {
      // Try to determine language from the release title
      enrichedProduct.metadataLanguage =
          _detectLanguage(enrichedProduct.productName);
    }

    enrichedProduct.releaseTime ??= '19:00';

    enrichedProduct.useRollingRelease ??= true;

    return enrichedProduct;
  }

  /// Enriches a track with metadata from multiple sources
  Future<Track> enrichTrack(Track track, Product product) async {
    // Create variables to hold the enriched data
    String title = track.title;
    String? version = track.version;
    bool isExplicit = track.isExplicit;
    List<String> primaryArtists = List.from(track.primaryArtists);
    List<String>? featuredArtists = track.featuredArtists != null
        ? List.from(track.featuredArtists!)
        : null;
    String genre = track.genre;
    List<Map<String, dynamic>> performersWithRoles =
        List.from(track.performersWithRoles);
    List<Map<String, dynamic>> songwritersWithRoles =
        List.from(track.songwritersWithRoles);
    List<Map<String, dynamic>> productionWithRoles =
        List.from(track.productionWithRoles);
    String isrc = track.isrc;
    String uid = track.uid;
    String artworkUrl = track.artworkUrl;
    String downloadUrl = track.downloadUrl;
    List<String>? remixers = track.remixers;
    String? ownership = track.ownership;
    String? country = track.country;
    String? nationality = track.nationality;
    String? lyrics = track.lyrics;
    Map<String, String>? syncedLyrics = track.syncedLyrics;
    int trackNumber = track.trackNumber; // Preserve original track number

    try {
      // Try to find track information on Spotify
      String artistQuery =
          track.primaryArtists.isNotEmpty ? track.primaryArtists[0] : '';
      String titleQuery = track.title;

      if (artistQuery.isNotEmpty && titleQuery.isNotEmpty) {
        final searchQuery = 'track:$titleQuery artist:$artistQuery';
        final searchResults = await _searchSpotifyTracks(searchQuery);

        if (searchResults.isNotEmpty) {
          final trackDetails = searchResults[0];

          // Get ISRC if available
          if (isrc.isEmpty &&
              trackDetails['external_ids'] != null &&
              trackDetails['external_ids']['isrc'] != null) {
            isrc = trackDetails['external_ids']['isrc'];
          }

          // Get explicit flag
          if (trackDetails['explicit'] != null) {
            isExplicit = trackDetails['explicit'];
          }

          // Get artists information
          if (trackDetails['artists'] != null &&
              (trackDetails['artists'] as List).isNotEmpty) {
            List<String> spotifyPrimaryArtists = [];
            List<String> spotifyFeaturedArtists = [];

            for (var i = 0; i < trackDetails['artists'].length; i++) {
              String artistName = trackDetails['artists'][i]['name'];

              // First artist is primary, others are featuring
              if (i == 0) {
                spotifyPrimaryArtists.add(artistName);
              } else {
                spotifyFeaturedArtists.add(artistName);
              }
            }

            // Only update if our track doesn't already have this info
            if (primaryArtists.isEmpty) {
              primaryArtists = spotifyPrimaryArtists;
            }

            if (spotifyFeaturedArtists.isNotEmpty) {
              featuredArtists = featuredArtists ?? [];
              if (featuredArtists.isEmpty) {
                featuredArtists = spotifyFeaturedArtists;
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching track with Spotify: $e');
    }

    // Try to find track information on Discogs
    try {
      String trackTitle = track.title;
      String artistName =
          track.primaryArtists.isNotEmpty ? track.primaryArtists[0] : '';
      String albumTitle = product.productName;

      if (trackTitle.isNotEmpty && artistName.isNotEmpty) {
        final discogsData = await _searchDiscogs(albumTitle, artistName);

        if (discogsData != null &&
            discogsData['results'] != null &&
            (discogsData['results'] as List).isNotEmpty) {
          final release = discogsData['results'][0];

          // Get release details if we have a Discogs ID
          if (release['id'] != null) {
            final releaseDetails =
                await _getDiscogsReleaseDetails(release['id'].toString());

            if (releaseDetails != null && releaseDetails['tracklist'] != null) {
              // Find the matching track in the tracklist
              for (var trackData in releaseDetails['tracklist']) {
                if (trackData['title'].toString().toLowerCase() ==
                    trackTitle.toLowerCase()) {
                  // If we found a matching track, extract additional information

                  // Extract performers if available
                  if (trackData['extraartists'] != null) {
                    List<Map<String, dynamic>> discogsWriters = [];
                    List<Map<String, dynamic>> discogsProducers = [];

                    for (var artist in trackData['extraartists']) {
                      String role =
                          artist['role']?.toString().toLowerCase() ?? '';
                      String name = artist['name'] ?? '';

                      if (role.contains('writer') ||
                          role.contains('composer') ||
                          role.contains('lyricist')) {
                        discogsWriters.add({
                          'name': name,
                          'roles': ['Writer']
                        });
                      } else if (role.contains('producer')) {
                        discogsProducers.add({
                          'name': name,
                          'roles': ['Producer']
                        });
                      }
                    }

                    if (discogsWriters.isNotEmpty &&
                        songwritersWithRoles.isEmpty) {
                      songwritersWithRoles = discogsWriters;
                    }

                    if (discogsProducers.isNotEmpty &&
                        productionWithRoles.isEmpty) {
                      productionWithRoles = discogsProducers;
                    }
                  }

                  break;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching track with Discogs: $e');
    }

    // Try to find track information on MusicBrainz
    try {
      String trackTitle = track.title;
      String artistName =
          track.primaryArtists.isNotEmpty ? track.primaryArtists[0] : '';

      if (trackTitle.isNotEmpty && artistName.isNotEmpty) {
        final mbData =
            await _searchMusicBrainzRecordings(trackTitle, artistName);

        if (mbData != null &&
            mbData['recordings'] != null &&
            (mbData['recordings'] as List).isNotEmpty) {
          final recording = mbData['recordings'][0];

          // Look for songwriter credits
          if (recording['artist-credit'] != null) {
            List<Map<String, dynamic>> mbSongwriters = [];

            for (var credit in recording['artist-credit']) {
              if (credit is Map &&
                  credit['artist'] != null &&
                  credit['artist']['name'] != null) {
                String artistName = credit['artist']['name'];

                // Only add if not already in primary artists
                if (!primaryArtists.contains(artistName)) {
                  mbSongwriters.add({
                    'name': artistName,
                    'roles': ['Writer']
                  });
                }
              }
            }

            if (mbSongwriters.isNotEmpty && songwritersWithRoles.isEmpty) {
              for (var writer in mbSongwriters) {
                if (!songwritersWithRoles
                    .any((item) => item['name'] == writer['name'])) {
                  songwritersWithRoles.add(writer);
                }
              }
            }
          }

          // Look for additional recording details
          if (recording['id'] != null) {
            final recordingDetails =
                await _getMusicBrainzRecordingDetails(recording['id']);

            if (recordingDetails != null) {
              // Extract additional information like producers
              if (recordingDetails['relationships'] != null) {
                List<Map<String, dynamic>> mbProducers = [];

                for (var relationship in recordingDetails['relationships']) {
                  if (relationship['type'] == 'producer' &&
                      relationship['artist'] != null &&
                      relationship['artist']['name'] != null) {
                    String producerName = relationship['artist']['name'];
                    mbProducers.add({
                      'name': producerName,
                      'roles': ['Producer']
                    });
                  }
                }

                if (mbProducers.isNotEmpty && productionWithRoles.isEmpty) {
                  for (var producer in mbProducers) {
                    if (!productionWithRoles
                        .any((item) => item['name'] == producer['name'])) {
                      productionWithRoles.add(producer);
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching track with MusicBrainz: $e');
    }

    // Try Last.fm for additional track information
    try {
      String trackTitle = track.title;
      String artistName =
          track.primaryArtists.isNotEmpty ? track.primaryArtists[0] : '';

      if (trackTitle.isNotEmpty && artistName.isNotEmpty) {
        final lastFmData = await _getLastFmTrackInfo(artistName, trackTitle);

        if (lastFmData != null && lastFmData['track'] != null) {
          final trackInfo = lastFmData['track'];

          // Get tags if available
          if (trackInfo['toptags'] != null &&
              trackInfo['toptags']['tag'] != null) {
            final tags = trackInfo['toptags']['tag'] as List;
            if (tags.isNotEmpty && genre.isEmpty) {
              // Map Last.fm tags to a standard genre
              final tagName = tags[0]['name'].toString().toLowerCase();
              genre = _mapLastFmTagToGenre(tagName);
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error enriching track with Last.fm: $e');
    }

    // If we still don't have an ISRC, we should generate one
    if (isrc.isEmpty) {
      isrc = _generateTemporaryISRC();
    }

    // If we don't have artwork URL, use the product's
    if (artworkUrl.isEmpty && product.coverImage.isNotEmpty) {
      artworkUrl = product.coverImage;
    }

    // Create and return a new Track with the enriched data
    return Track(
      trackNumber: trackNumber, // Add the required trackNumber parameter
      title: title,
      version: version,
      isExplicit: isExplicit,
      primaryArtists: primaryArtists,
      primaryArtistIds: track.primaryArtistIds, // Preserve existing IDs
      featuredArtists: featuredArtists,
      featuredArtistIds: track.featuredArtistIds, // Preserve existing IDs
      genre: genre,
      performersWithRoles: performersWithRoles,
      songwritersWithRoles: songwritersWithRoles,
      productionWithRoles: productionWithRoles,
      isrc: isrc,
      uid: uid,
      artworkUrl: artworkUrl,
      downloadUrl: downloadUrl,
      remixers: remixers,
      ownership: ownership,
      country: country,
      nationality: nationality,
      lyrics: lyrics,
      syncedLyrics: syncedLyrics,
    );
  }

  // Helper methods

  /// Merges data from two Product objects, prioritizing the original where data exists
  Product _mergeProductData(Product original, Product enrichment) {
    Product merged = original;

    // Only update fields that are empty in the original
    if (original.upc.isEmpty && enrichment.upc.isNotEmpty) {
      merged.upc = enrichment.upc;
      merged.autoGenerateUPC = false;
    }

    if (original.genre.isEmpty && enrichment.genre.isNotEmpty) {
      merged.genre = enrichment.genre;
    }

    if (original.subgenre.isEmpty && enrichment.subgenre.isNotEmpty) {
      merged.subgenre = enrichment.subgenre;
    }

    if (original.label == "BlackMatter Portal" &&
        enrichment.label != "BlackMatter Portal") {
      merged.label = enrichment.label;

      // Update p-line and c-line
      String year = DateTime.now().year.toString();
      if (enrichment.pLineYear.isNotEmpty) {
        year = enrichment.pLineYear;
      } else if (original.pLineYear.isNotEmpty) {
        year = original.pLineYear;
      }

      merged.pLine = "℗ $year ${enrichment.label}";
      merged.cLine = "© $year ${enrichment.label}";
      merged.pLineYear = year;
      merged.cLineYear = year;
    }

    if (original.metadataLanguage.isEmpty &&
        enrichment.metadataLanguage.isNotEmpty) {
      merged.metadataLanguage = enrichment.metadataLanguage;
    }

    if (original.coverImage.isEmpty && enrichment.coverImage.isNotEmpty) {
      merged.coverImage = enrichment.coverImage;
      merged.artworkUrl = enrichment.coverImage;
    }

    if (original.releaseTitle.isEmpty && original.productName.isNotEmpty) {
      merged.releaseTitle = original.productName;
    }

    // Preserve artist IDs if present in original
    if (original.productArtistIds != null &&
        original.productArtistIds!.isNotEmpty) {
      merged.productArtistIds = original.productArtistIds;
    } else if (enrichment.productArtistIds != null &&
        enrichment.productArtistIds!.isNotEmpty) {
      merged.productArtistIds = enrichment.productArtistIds;
    }

    return merged;
  }

  /// Searches for releases on Discogs
  Future<Map<String, dynamic>?> _searchDiscogs(
      String releaseTitle, String artistName) async {
    try {
      final query = Uri.encodeComponent('$releaseTitle $artistName');
      final response = await http.get(
        Uri.parse(
            'https://api.discogs.com/database/search?q=$query&type=release'),
        headers: {
          'User-Agent': 'Portal/1.0',
          'Authorization':
              'Discogs key=$_discogsConsumerKey, secret=$_discogsConsumerSecret',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error searching Discogs: $e');
    }

    return null;
  }

  /// Gets detailed release information from Discogs
  Future<Map<String, dynamic>?> _getDiscogsReleaseDetails(
      String releaseId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.discogs.com/releases/$releaseId'),
        headers: {
          'User-Agent': 'Portal/1.0',
          'Authorization':
              'Discogs key=$_discogsConsumerKey, secret=$_discogsConsumerSecret',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error getting Discogs release details: $e');
    }

    return null;
  }

  /// Gets album information from Last.fm
  Future<Map<String, dynamic>?> _getLastFmAlbumInfo(
      String artistName, String albumName) async {
    try {
      final artist = Uri.encodeComponent(artistName);
      final album = Uri.encodeComponent(albumName);

      final response = await http.get(
        Uri.parse(
            'https://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=$artist&album=$album&api_key=$_lastFmApiKey&format=json'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error getting Last.fm album info: $e');
    }

    return null;
  }

  /// Gets track information from Last.fm
  Future<Map<String, dynamic>?> _getLastFmTrackInfo(
      String artistName, String trackName) async {
    try {
      final artist = Uri.encodeComponent(artistName);
      final track = Uri.encodeComponent(trackName);

      final response = await http.get(
        Uri.parse(
            'https://ws.audioscrobbler.com/2.0/?method=track.getinfo&artist=$artist&track=$track&api_key=$_lastFmApiKey&format=json'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error getting Last.fm track info: $e');
    }

    return null;
  }

  /// Maps Last.fm tags to standard music genres
  String _mapLastFmTagToGenre(String tag) {
    final genreMap = {
      'hip hop': 'Hip-Hop',
      'hip-hop': 'Hip-Hop',
      'rap': 'Hip-Hop',
      'trap': 'Hip-Hop',
      'r&b': 'R&B/Soul',
      'rnb': 'R&B/Soul',
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
      'latino': 'Latin',
      'world': 'World',
      'indie': 'Alternative',
      'alternative': 'Alternative',
      'ambient': 'New Age',
      'soundtrack': 'Soundtrack',
      'gospel': 'Religious',
      'christian': 'Religious',
      // Add more mappings as needed
    };

    // Find the first matching genre key
    for (var key in genreMap.keys) {
      if (tag.contains(key)) {
        return genreMap[key]!;
      }
    }

    // Default genre if no match found
    return 'Pop';
  }

  /// Searches for albums on Spotify
  Future<List<dynamic>> _searchSpotify(String query) async {
    try {
      final results = await _spotifyService.searchArtist(query);
      if (results['albums'] != null && results['albums']['items'] != null) {
        return results['albums']['items'];
      }
    } catch (e) {
      developer.log('Error searching Spotify: $e');
    }

    return [];
  }

  /// Searches for tracks on Spotify
  Future<List<dynamic>> _searchSpotifyTracks(String query) async {
    try {
      final accessToken = await _spotifyService.getAccessToken();

      final response = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?q=$query&type=track&limit=5'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tracks'] != null && data['tracks']['items'] != null) {
          return data['tracks']['items'];
        }
      }
    } catch (e) {
      developer.log('Error searching Spotify tracks: $e');
    }

    return [];
  }

  /// Searches for releases on MusicBrainz
  Future<Map<String, dynamic>?> _searchMusicBrainz(
      String releaseTitle, String artistName) async {
    try {
      final query = Uri.encodeComponent(
          'release:"$releaseTitle" AND artist:"$artistName"');
      final response = await http.get(
        Uri.parse(
            'https://musicbrainz.org/ws/2/release/?query=$query&fmt=json'),
        headers: {'User-Agent': _musicBrainzUserAgent},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error searching MusicBrainz: $e');
    }

    return null;
  }

  /// Searches for recordings (tracks) on MusicBrainz
  Future<Map<String, dynamic>?> _searchMusicBrainzRecordings(
      String trackTitle, String artistName) async {
    try {
      final query = Uri.encodeComponent(
          'recording:"$trackTitle" AND artist:"$artistName"');
      final response = await http.get(
        Uri.parse(
            'https://musicbrainz.org/ws/2/recording/?query=$query&fmt=json'),
        headers: {'User-Agent': _musicBrainzUserAgent},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error searching MusicBrainz recordings: $e');
    }

    return null;
  }

  /// Gets detailed release information from MusicBrainz
  Future<Map<String, dynamic>?> _getMusicBrainzReleaseDetails(
      String mbid) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://musicbrainz.org/ws/2/release/$mbid?inc=labels+recordings+artist-credits&fmt=json'),
        headers: {'User-Agent': _musicBrainzUserAgent},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error getting MusicBrainz release details: $e');
    }

    return null;
  }

  /// Gets detailed recording information from MusicBrainz
  Future<Map<String, dynamic>?> _getMusicBrainzRecordingDetails(
      String mbid) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://musicbrainz.org/ws/2/recording/$mbid?inc=artist-credits+work-rels+artist-rels&fmt=json'),
        headers: {'User-Agent': _musicBrainzUserAgent},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      developer.log('Error getting MusicBrainz recording details: $e');
    }

    return null;
  }

  /// Simple language detection logic
  String _detectLanguage(String text) {
    // Check for common Spanish characters and words
    final spanishChars = RegExp(r'[áéíóúñ¿¡]');
    final spanishWords = [
      'el',
      'la',
      'los',
      'las',
      'de',
      'en',
      'con',
      'por',
      'para',
      'mi',
      'tu',
      'su'
    ];

    if (spanishChars.hasMatch(text.toLowerCase())) {
      return 'es';
    }

    // Split into words and check for Spanish common words
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    for (var word in words) {
      if (spanishWords.contains(word)) {
        return 'es';
      }
    }

    return defaultMetadataLanguage;
  }

  /// Generate a temporary ISRC code
  /// Format: [Country Code (2)][Registrant Code (3)][Year (2)][Designation (5)]
  String _generateTemporaryISRC() {
    // USLZJ = US + LZJ (BlackMatter placeholder registrant code)
    final countryRegistrant = 'USLZJ';

    // Current year's last 2 digits
    final year = DateTime.now().year.toString().substring(2);

    // Random 5-digit designation
    final designation =
        (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
            .toString()
            .substring(0, 5);

    return '$countryRegistrant$year$designation';
  }
}
