class Track {
  int trackNumber;
  String title;
  String? version;
  bool isExplicit;
  List<String> primaryArtists;
  List<String>? primaryArtistIds; // Add field for primary artist IDs
  List<String>? featuredArtists;
  List<String>? featuredArtistIds; // Add field for featured artist IDs
  String genre;
  final List<Map<String, dynamic>> performersWithRoles;
  final List<Map<String, dynamic>> songwritersWithRoles;
  final List<Map<String, dynamic>> productionWithRoles;
  List<String>? remixers;
  String? ownership;
  String? country;
  String? nationality;
  String isrc;
  String uid;
  String artworkUrl;
  String downloadUrl;
  String? lyrics;
  Map<String, String>? syncedLyrics;
  Track({
    required this.trackNumber, // int
    required this.title, // String
    this.version, // String?
    required this.isExplicit, // bool
    required this.primaryArtists, // List<String>
    this.primaryArtistIds, // List<String>?
    this.featuredArtists, // List<String>
    this.featuredArtistIds, // List<String>?
    required this.genre, // String
    required this.performersWithRoles, // List<Map<String, dynamic>>
    required this.songwritersWithRoles, // List<Map<String, dynamic>>
    required this.productionWithRoles, // List<Map<String, dynamic>>
    required this.isrc, // String
    required this.uid, // String
    this.remixers, // List<String>?
    this.ownership, // String?
    this.country, // String?
    this.nationality, // String?
    required this.artworkUrl, // String
    required this.downloadUrl, // String
    this.lyrics, // String?
    this.syncedLyrics, // Map<String, String>?
  });

  String get fileName => title;

  factory Track.fromMap(Map<String, dynamic> map) {
    // Always use uid if present, otherwise fallback to id
    final String uid = map['uid']?.toString() ?? map['id']?.toString() ?? '';
    assert(uid.isNotEmpty, 'Track.fromMap: Both uid and id are missing or empty in map: '
        'map = $map');
    return Track(
      uid: uid,
      trackNumber:
          map['trackNumber'] is int
              ? map['trackNumber']
              : int.tryParse(map['trackNumber']?.toString() ?? '') ?? 0,
      title: map['title'] ?? '',
      version: map['version'],
      isExplicit: map['isExplicit'] ?? false,
      primaryArtists: List<String>.from(map['primaryArtists'] ?? []),
      primaryArtistIds:
          map['primaryArtistIds'] != null
              ? List<String>.from(map['primaryArtistIds'])
              : null,
      featuredArtists:
          map['featuredArtists'] != null
              ? List<String>.from(map['featuredArtists'])
              : null,
      featuredArtistIds:
          map['featuredArtistIds'] != null
              ? List<String>.from(map['featuredArtistIds'])
              : null,
      genre: map['genre'] ?? '',
      performersWithRoles:
          map['performersWithRoles'] != null
              ? List<Map<String, dynamic>>.from(
                (map['performersWithRoles'] as List).map(
                  (e) => Map<String, dynamic>.from(e),
                ),
              )
              : [],
      songwritersWithRoles:
          map['songwritersWithRoles'] != null
              ? List<Map<String, dynamic>>.from(
                (map['songwritersWithRoles'] as List).map(
                  (e) => Map<String, dynamic>.from(e),
                ),
              )
              : [],
      productionWithRoles:
          map['productionWithRoles'] != null
              ? List<Map<String, dynamic>>.from(
                (map['productionWithRoles'] as List).map(
                  (e) => Map<String, dynamic>.from(e),
                ),
              )
              : [],
      remixers:
          map['remixers'] != null ? List<String>.from(map['remixers']) : null,
      ownership: map['ownership'],
      country: map['country'],
      nationality: map['nationality'],
      isrc: map['isrc'] ?? '',
      artworkUrl: map['artworkUrl'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      lyrics: map['lyrics'],
      syncedLyrics:
          map['syncedLyrics'] != null
              ? Map<String, String>.from(map['syncedLyrics'])
              : null,
    );
  }
}
