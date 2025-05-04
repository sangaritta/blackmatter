import 'package:portal/Models/track.dart';
import 'package:flutter/foundation.dart';

class Product extends ChangeNotifier {
  String type;
  String productName;
  List<String> productArtists;
  List<String>? productArtistIds; // Artist IDs
  String cLine;
  String pLine;
  String price;
  String label;
  String releaseDate;
  String upc;
  String uid;
  List<Track> songs;
  String coverImage;
  String state;
  String userId; // User ID who owns this product
 // User ID who owns this product

  // Additional fields needed for complete product metadata
  String cLineYear;
  String pLineYear;
  bool autoGenerateUPC;
  String metadataLanguage;
  String releaseTitle;
  String releaseVersion;
  String genre;
  String subgenre;
  bool useRollingRelease;
  String releaseTime;
  String artworkUrl;
  String country;
  List<String>? platforms; // Platforms for distribution services
  List<Map<String, String>>? platformsSelected; // Add platformsSelected field
  Product({
    required this.type,
    required this.productName,
    required this.productArtists,
    this.productArtistIds,
    required this.cLine,
    required this.pLine,
    required this.price,
    required this.label,
    required this.releaseDate,
    required this.upc,
    required this.uid,
    required this.songs,
    required this.coverImage,
    required this.state,
    required this.userId, // Required userId field
    this.cLineYear = '',
    this.pLineYear = '',
    this.autoGenerateUPC = true,
    this.metadataLanguage = 'en',
    this.releaseTitle = '',
    this.releaseVersion = '',
    this.genre = 'Pop', // Default to Pop to avoid null
    this.subgenre = 'Pop', // Default to Pop to avoid null
    this.useRollingRelease = true,
    this.releaseTime = '19:00',
    this.artworkUrl = '',
    this.country = 'US',
    this.platforms,
    this.platformsSelected, // Add parameter for platformsSelected
  });

  // Convert to a complete map with all necessary metadata fields
  Map<String, dynamic> toDetailedMap() {
    final currentYear = DateTime.now().year.toString();

    // Default platforms for distribution
    final defaultPlatforms = [
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

    // Create default platformsSelected if not provided
    final defaultPlatformsSelected = [
      {'name': 'Spotify', 'id': 'spotify_001'},
      {'name': 'Apple', 'id': 'apple_001'},
      {'name': 'YouTube', 'id': 'youtube_001'},
      {'name': 'Amazon', 'id': 'amazon_001'},
      {'name': 'Deezer', 'id': 'deezer_001'},
      {'name': 'TikTok', 'id': 'tiktok_001'},
    ];

    return {
      'type': type,
      'productName': productName,
      'productArtists': productArtists,
      'productArtistIds': productArtistIds ?? [],
      'primaryArtists': productArtists,
      'primaryArtistIds': productArtistIds ?? [],
      'cLine': cLine,
      'pLine': pLine,
      'price': price,
      'label': label,
      'releaseDate': releaseDate,
      'upc': upc,
      'uid': uid,
      'state': state,
      'coverImage': coverImage,
      'cLineYear': cLineYear.isNotEmpty ? cLineYear : currentYear,
      'pLineYear': pLineYear.isNotEmpty ? pLineYear : currentYear,
      'autoGenerateUPC': autoGenerateUPC,
      'metadataLanguage': metadataLanguage,
      'releaseTitle': releaseTitle.isNotEmpty ? releaseTitle : productName,
      'releaseVersion': releaseVersion,
      'genre': genre.isNotEmpty ? genre : 'Pop',
      'subgenre':
          subgenre.isNotEmpty ? subgenre : (genre.isNotEmpty ? genre : 'Pop'),
      'useRollingRelease': useRollingRelease,
      'releaseTime': releaseTime,
      'artworkUrl': artworkUrl.isNotEmpty ? artworkUrl : coverImage,
      'country': country,
      'platforms': platforms ?? defaultPlatforms,
      'platformsSelected': platformsSelected ?? defaultPlatformsSelected,
      'trackCount': songs.length,
    };
  }
}
