// Track model for Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  final int trackNumber;
  final String title;
  final String? version;
  final bool isExplicit;
  final List<String> primaryArtists;
  final List<String>? primaryArtistIds;
  final List<String>? featuredArtists;
  final List<String>? featuredArtistIds;
  final String genre;
  final List<Map<String, dynamic>> performersWithRoles;
  final List<Map<String, dynamic>> songwritersWithRoles;
  final List<Map<String, dynamic>> productionWithRoles;
  final List<String>? remixers;
  final String? ownership;
  final String? country;
  final String? nationality;
  final String isrc;
  final String uid;
  final String artworkUrl;
  final String downloadUrl;
  final String? lyrics;
  final Map<String, String>? syncedLyrics;
  final String? lyricsLanguage;
  final Map<String, String>? translations;
  final List<String>? tags;
  final String id;
  final String productId;
  final String projectId;
  final String userId;
  final String name;
  final String fileName;
  final String storagePath;
  final String isrcCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? uploadedAt;

  Track({
    required this.trackNumber,
    required this.title,
    this.version,
    required this.isExplicit,
    required this.primaryArtists,
    this.primaryArtistIds,
    this.featuredArtists,
    this.featuredArtistIds,
    required this.genre,
    required this.performersWithRoles,
    required this.songwritersWithRoles,
    required this.productionWithRoles,
    this.remixers,
    this.ownership,
    this.country,
    this.nationality,
    required this.isrc,
    required this.uid,
    required this.artworkUrl,
    required this.downloadUrl,
    this.lyrics,
    this.syncedLyrics,
    this.lyricsLanguage,
    this.translations,
    this.tags,
    required this.id,
    required this.productId,
    required this.projectId,
    required this.userId,
    required this.name,
    required this.fileName,
    required this.storagePath,
    required this.isrcCode,
    this.createdAt,
    this.updatedAt,
    this.uploadedAt,
  });

  factory Track.fromMap(Map<String, dynamic> map, String id) {
    return Track(
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
      uid: map['uid'] ?? '',
      artworkUrl: map['artworkUrl'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      lyrics: map['lyrics'],
      syncedLyrics:
          map['syncedLyrics'] != null
              ? Map<String, String>.from(map['syncedLyrics'])
              : null,
      lyricsLanguage: map['lyricsLanguage'],
      translations:
          map['translations'] != null
              ? Map<String, String>.from(map['translations'])
              : null,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      id: id,
      productId: map['productId'] ?? '',
      projectId: map['projectId'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      fileName: map['fileName'] ?? '',
      storagePath: map['storagePath'] ?? '',
      isrcCode: map['isrcCode'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] as Timestamp).toDate()
              : null,
      uploadedAt:
          map['uploadedAt'] != null
              ? (map['uploadedAt'] as Timestamp).toDate()
              : null,
    );
  }

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
      'lyricsLanguage': lyricsLanguage,
      'translations': translations,
      'tags': tags,
      'productId': productId,
      'projectId': projectId,
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

  Track copyWith({
    int? trackNumber,
    String? title,
    String? version,
    bool? isExplicit,
    List<String>? primaryArtists,
    List<String>? primaryArtistIds,
    List<String>? featuredArtists,
    List<String>? featuredArtistIds,
    String? genre,
    List<Map<String, dynamic>>? performersWithRoles,
    List<Map<String, dynamic>>? songwritersWithRoles,
    List<Map<String, dynamic>>? productionWithRoles,
    List<String>? remixers,
    String? ownership,
    String? country,
    String? nationality,
    String? isrc,
    String? uid,
    String? artworkUrl,
    String? downloadUrl,
    String? lyrics,
    Map<String, String>? syncedLyrics,
    String? lyricsLanguage,
    Map<String, String>? translations,
    List<String>? tags,
    String? id,
    String? productId,
    String? projectId,
    String? userId,
    String? name,
    String? fileName,
    String? storagePath,
    String? isrcCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? uploadedAt,
  }) {
    return Track(
      trackNumber: trackNumber ?? this.trackNumber,
      title: title ?? this.title,
      version: version ?? this.version,
      isExplicit: isExplicit ?? this.isExplicit,
      primaryArtists: primaryArtists ?? this.primaryArtists,
      primaryArtistIds: primaryArtistIds ?? this.primaryArtistIds,
      featuredArtists: featuredArtists ?? this.featuredArtists,
      featuredArtistIds: featuredArtistIds ?? this.featuredArtistIds,
      genre: genre ?? this.genre,
      performersWithRoles: performersWithRoles ?? this.performersWithRoles,
      songwritersWithRoles: songwritersWithRoles ?? this.songwritersWithRoles,
      productionWithRoles: productionWithRoles ?? this.productionWithRoles,
      remixers: remixers ?? this.remixers,
      ownership: ownership ?? this.ownership,
      country: country ?? this.country,
      nationality: nationality ?? this.nationality,
      isrc: isrc ?? this.isrc,
      uid: uid ?? this.uid,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      lyrics: lyrics ?? this.lyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      lyricsLanguage: lyricsLanguage ?? this.lyricsLanguage,
      translations: translations ?? this.translations,
      tags: tags ?? this.tags,
      id: id ?? this.id,
      productId: productId ?? this.productId,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      isrcCode: isrcCode ?? this.isrcCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  // Add a static empty Track factory for fallback usage
  static Track empty() {
    return Track(
      id: '',
      productId: '',
      projectId: '',
      userId: '',
      name: '',
      fileName: '',
      storagePath: '',
      isrcCode: '',
      trackNumber: 0,
      title: '',
      version: '',
      isExplicit: false,
      primaryArtistIds: const [],
      featuredArtists: const [],
      featuredArtistIds: const [],
      genre: '',
      performersWithRoles: const [],
      songwritersWithRoles: const [],
      productionWithRoles: const [],
      remixers: const [],
      ownership: '',
      country: '',
      nationality: '',
      artworkUrl: '',
      downloadUrl: '',
      lyrics: '',
      syncedLyrics: const {},
      lyricsLanguage: '',
      translations: const {},
      tags: const [],
      createdAt: null,
      updatedAt: null,
      uploadedAt: null,
      primaryArtists: const [],
      isrc: '',
      uid: '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          trackNumber == other.trackNumber &&
          title == other.title &&
          version == other.version &&
          isExplicit == other.isExplicit &&
          primaryArtists == other.primaryArtists &&
          primaryArtistIds == other.primaryArtistIds &&
          featuredArtists == other.featuredArtists &&
          featuredArtistIds == other.featuredArtistIds &&
          genre == other.genre &&
          performersWithRoles == other.performersWithRoles &&
          songwritersWithRoles == other.songwritersWithRoles &&
          productionWithRoles == other.productionWithRoles &&
          remixers == other.remixers &&
          ownership == other.ownership &&
          country == other.country &&
          nationality == other.nationality &&
          isrc == other.isrc &&
          uid == other.uid &&
          artworkUrl == other.artworkUrl &&
          downloadUrl == other.downloadUrl &&
          lyrics == other.lyrics &&
          syncedLyrics == other.syncedLyrics &&
          lyricsLanguage == other.lyricsLanguage &&
          translations == other.translations &&
          tags == other.tags &&
          id == other.id &&
          productId == other.productId &&
          userId == other.userId &&
          name == other.name &&
          fileName == other.fileName &&
          storagePath == other.storagePath &&
          isrcCode == other.isrcCode &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          uploadedAt == other.uploadedAt;

  @override
  int get hashCode =>
      trackNumber.hashCode ^
      title.hashCode ^
      version.hashCode ^
      isExplicit.hashCode ^
      primaryArtists.hashCode ^
      primaryArtistIds.hashCode ^
      featuredArtists.hashCode ^
      featuredArtistIds.hashCode ^
      genre.hashCode ^
      performersWithRoles.hashCode ^
      songwritersWithRoles.hashCode ^
      productionWithRoles.hashCode ^
      remixers.hashCode ^
      ownership.hashCode ^
      country.hashCode ^
      nationality.hashCode ^
      isrc.hashCode ^
      uid.hashCode ^
      artworkUrl.hashCode ^
      downloadUrl.hashCode ^
      lyrics.hashCode ^
      syncedLyrics.hashCode ^
      lyricsLanguage.hashCode ^
      translations.hashCode ^
      tags.hashCode ^
      id.hashCode ^
      productId.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      fileName.hashCode ^
      storagePath.hashCode ^
      isrcCode.hashCode ^
      (createdAt?.hashCode ?? 0) ^
      (updatedAt?.hashCode ?? 0) ^
      (uploadedAt?.hashCode ?? 0);
}
