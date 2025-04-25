// Product model for Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portal/models/track.dart' as model_track;
import 'package:portal/models/metadata_language.dart';

class Product {
  final String id;
  final String userId;
  final String projectId;
  final String releaseTitle;
  final String releaseVersion;
  final String label;
  final String genre;
  final String subgenre;
  final MetadataLanguage? metadataLanguage;
  final String type;
  final String price;
  final String state;
  final String coverImage;
  final String previewArtUrl;
  final String cLine;
  final String cLineYear;
  final String pLine;
  final String pLineYear;
  final String upc;
  final String uid;
  final bool autoGenerateUPC;
  final int trackCount;
  final List<String> primaryArtists;
  final List<String> primaryArtistIds;
  final List<model_track.Track> tracks;
  final List<String>? platforms;
  final List<Map<String, String>>? platformsSelected;
  final bool useRollingRelease;
  final String releaseTime;
  final String artworkUrl;
  final String country;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, String>? originalPath;
  final String? timeZone;

  // Alias for backwards compatibility if needed
  List<model_track.Track> get songs => tracks;

  Product({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.releaseTitle,
    required this.releaseVersion,
    required this.label,
    required this.genre,
    required this.subgenre,
    required this.metadataLanguage,
    required this.type,
    required this.price,
    required this.state,
    required this.coverImage,
    required this.previewArtUrl,
    required this.cLine,
    required this.cLineYear,
    required this.pLine,
    required this.pLineYear,
    required this.upc,
    required this.uid,
    required this.autoGenerateUPC,
    required this.trackCount,
    required this.primaryArtists,
    required this.primaryArtistIds,
    required this.tracks,
    this.platforms,
    this.platformsSelected,
    this.useRollingRelease = true,
    this.releaseTime = '19:00',
    this.artworkUrl = '',
    this.country = 'US',
    this.createdAt,
    this.updatedAt,
    this.originalPath,
    this.timeZone,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      userId: data['userId'] ?? '',
      projectId: data['projectId'] ?? '',
      releaseTitle: data['releaseTitle'] ?? '',
      releaseVersion: data['releaseVersion'] ?? '',
      label: data['label'] ?? '',
      genre: data['genre'] ?? '',
      subgenre: data['subgenre'] ?? '',
      metadataLanguage: data['metadataLanguage'] is Map ? MetadataLanguage.fromMap(data['metadataLanguage']) : (data['metadataLanguage'] is String && data['metadataLanguage'].isNotEmpty ? MetadataLanguage(data['metadataLanguage'], data['metadataLanguage']) : null),
      type: data['type'] ?? '',
      price: data['price'] ?? '',
      state: data['state'] ?? '',
      coverImage: data['coverImage'] ?? '',
      previewArtUrl: data['previewArtUrl'] ?? '',
      cLine: data['cLine'] ?? '',
      cLineYear: data['cLineYear'] ?? '',
      pLine: data['pLine'] ?? '',
      pLineYear: data['pLineYear'] ?? '',
      upc: data['upc'] ?? '',
      uid: data['uid'] ?? '',
      autoGenerateUPC: data['autoGenerateUPC'] ?? false,
      trackCount: data['trackCount'] ?? 0,
      primaryArtists: (data['primaryArtists'] as List?)?.map((e) => e.toString()).toList() ?? [],
      primaryArtistIds: (data['primaryArtistIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tracks: (data['tracks'] as List?)?.map((e) => model_track.Track.fromMap(e as Map<String, dynamic>, e['id'] ?? '')).toList() ?? [],
      platforms: data['platforms'] != null ? List<String>.from(data['platforms']) : null,
      platformsSelected: data['platformsSelected'] != null ? List<Map<String, String>>.from((data['platformsSelected'] as List).map((e) => Map<String, String>.from(e))) : null,
      useRollingRelease: data['useRollingRelease'] ?? true,
      releaseTime: data['releaseTime'] ?? '19:00',
      artworkUrl: data['artworkUrl'] ?? '',
      country: data['country'] ?? 'US',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      originalPath: data['originalPath'] != null ? Map<String, String>.from(data['originalPath']) : null,
      timeZone: data['timeZone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'projectId': projectId,
      'releaseTitle': releaseTitle,
      'releaseVersion': releaseVersion,
      'label': label,
      'genre': genre,
      'subgenre': subgenre,
      'metadataLanguage': metadataLanguage?.toMap(),
      'type': type,
      'price': price,
      'state': state,
      'coverImage': coverImage,
      'previewArtUrl': previewArtUrl,
      'cLine': cLine,
      'cLineYear': cLineYear,
      'pLine': pLine,
      'pLineYear': pLineYear,
      'upc': upc,
      'uid': uid,
      'autoGenerateUPC': autoGenerateUPC,
      'trackCount': trackCount,
      'primaryArtists': primaryArtists,
      'primaryArtistIds': primaryArtistIds,
      'tracks': tracks.map((t) => t.toMap()).toList(),
      'platforms': platforms,
      'platformsSelected': platformsSelected,
      'useRollingRelease': useRollingRelease,
      'releaseTime': releaseTime,
      'artworkUrl': artworkUrl,
      'country': country,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'originalPath': originalPath,
      'timeZone': timeZone,
    }..removeWhere((key, value) => value == null);
  }

  Product copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? releaseTitle,
    String? releaseVersion,
    String? label,
    String? genre,
    String? subgenre,
    MetadataLanguage? metadataLanguage,
    String? type,
    String? price,
    String? state,
    String? coverImage,
    String? previewArtUrl,
    String? cLine,
    String? cLineYear,
    String? pLine,
    String? pLineYear,
    String? upc,
    String? uid,
    bool? autoGenerateUPC,
    int? trackCount,
    List<String>? primaryArtists,
    List<String>? primaryArtistIds,
    List<model_track.Track>? tracks,
    List<String>? platforms,
    List<Map<String, String>>? platformsSelected,
    bool? useRollingRelease,
    String? releaseTime,
    String? artworkUrl,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? originalPath,
    String? timeZone,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      releaseTitle: releaseTitle ?? this.releaseTitle,
      releaseVersion: releaseVersion ?? this.releaseVersion,
      label: label ?? this.label,
      genre: genre ?? this.genre,
      subgenre: subgenre ?? this.subgenre,
      metadataLanguage: metadataLanguage ?? this.metadataLanguage,
      type: type ?? this.type,
      price: price ?? this.price,
      state: state ?? this.state,
      coverImage: coverImage ?? this.coverImage,
      previewArtUrl: previewArtUrl ?? this.previewArtUrl,
      cLine: cLine ?? this.cLine,
      cLineYear: cLineYear ?? this.cLineYear,
      pLine: pLine ?? this.pLine,
      pLineYear: pLineYear ?? this.pLineYear,
      upc: upc ?? this.upc,
      uid: uid ?? this.uid,
      autoGenerateUPC: autoGenerateUPC ?? this.autoGenerateUPC,
      trackCount: trackCount ?? this.trackCount,
      primaryArtists: primaryArtists ?? this.primaryArtists,
      primaryArtistIds: primaryArtistIds ?? this.primaryArtistIds,
      tracks: tracks ?? this.tracks,
      platforms: platforms ?? this.platforms,
      platformsSelected: platformsSelected ?? this.platformsSelected,
      useRollingRelease: useRollingRelease ?? this.useRollingRelease,
      releaseTime: releaseTime ?? this.releaseTime,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      originalPath: originalPath ?? this.originalPath,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          projectId == other.projectId &&
          releaseTitle == other.releaseTitle &&
          releaseVersion == other.releaseVersion &&
          label == other.label &&
          genre == other.genre &&
          subgenre == other.subgenre &&
          metadataLanguage == other.metadataLanguage &&
          type == other.type &&
          price == other.price &&
          state == other.state &&
          coverImage == other.coverImage &&
          previewArtUrl == other.previewArtUrl &&
          cLine == other.cLine &&
          cLineYear == other.cLineYear &&
          pLine == other.pLine &&
          pLineYear == other.pLineYear &&
          upc == other.upc &&
          uid == other.uid &&
          autoGenerateUPC == other.autoGenerateUPC &&
          trackCount == other.trackCount &&
          primaryArtists == other.primaryArtists &&
          primaryArtistIds == other.primaryArtistIds &&
          tracks == other.tracks &&
          platforms == other.platforms &&
          platformsSelected == other.platformsSelected &&
          useRollingRelease == other.useRollingRelease &&
          releaseTime == other.releaseTime &&
          artworkUrl == other.artworkUrl &&
          country == other.country &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          originalPath == other.originalPath &&
          timeZone == other.timeZone;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      projectId.hashCode ^
      releaseTitle.hashCode ^
      releaseVersion.hashCode ^
      label.hashCode ^
      genre.hashCode ^
      subgenre.hashCode ^
      (metadataLanguage?.hashCode ?? 0) ^
      type.hashCode ^
      price.hashCode ^
      state.hashCode ^
      coverImage.hashCode ^
      previewArtUrl.hashCode ^
      cLine.hashCode ^
      cLineYear.hashCode ^
      pLine.hashCode ^
      pLineYear.hashCode ^
      upc.hashCode ^
      uid.hashCode ^
      autoGenerateUPC.hashCode ^
      trackCount.hashCode ^
      primaryArtists.hashCode ^
      primaryArtistIds.hashCode ^
      tracks.hashCode ^
      platforms.hashCode ^
      platformsSelected.hashCode ^
      useRollingRelease.hashCode ^
      releaseTime.hashCode ^
      artworkUrl.hashCode ^
      country.hashCode ^
      (createdAt?.hashCode ?? 0) ^
      (updatedAt?.hashCode ?? 0) ^
      (originalPath?.hashCode ?? 0) ^
      (timeZone?.hashCode ?? 0);
}
