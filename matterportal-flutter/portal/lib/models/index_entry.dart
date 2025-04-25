// IndexEntry model for Firestore product index
import 'package:cloud_firestore/cloud_firestore.dart';

class IndexEntry {
  final String id;
  final String name;
  final int trackCount;
  final DateTime? updatedAt;
  final String? releaseTitle;
  final String? releaseVersion;
  final String? type;
  final String? state;
  final String? coverImage;
  final List<String>? primaryArtists;
  final String? notes;
  final String? uid;
  final String? projectId;

  IndexEntry({
    required this.id,
    required this.name,
    required this.trackCount,
    this.updatedAt,
    this.releaseTitle,
    this.releaseVersion,
    this.type,
    this.state,
    this.coverImage,
    this.primaryArtists,
    this.notes,
    this.uid,
    this.projectId,
  });

  factory IndexEntry.fromMap(Map<String, dynamic> map, String id) {
    // Fix: Only use project fields if this is a project, otherwise parse as product
    final isProject = map['projectName'] != null;
    return IndexEntry(
      id: id,
      name: isProject
          ? map['projectName'] ?? ''
          : map['releaseTitle'] ?? map['name'] ?? '',
      releaseTitle: isProject ? null : map['releaseTitle'],
      releaseVersion: isProject ? null : map['releaseVersion'],
      primaryArtists: isProject
          ? (map['projectArtist'] != null ? [map['projectArtist']] : [])
          : (map['primaryArtists'] as List?)?.map((e) => e.toString()).toList() ?? [],
      type: map['type'],
      state: map['state'],
      trackCount: isProject ? 0 : (map['trackCount'] ?? 0),
      coverImage: map['coverImage'],
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      notes: isProject ? map['notes'] : null,
      uid: isProject ? map['uid'] : null,
      projectId: isProject ? null : map['projectId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trackCount': trackCount,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'releaseTitle': releaseTitle,
      'releaseVersion': releaseVersion,
      'state': state,
      'type': type,
      'coverImage': coverImage,
      'primaryArtists': primaryArtists,
      'notes': notes,
      'uid': uid,
      'projectId': projectId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndexEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          trackCount == other.trackCount &&
          updatedAt == other.updatedAt &&
          releaseTitle == other.releaseTitle &&
          releaseVersion == other.releaseVersion &&
          state == other.state &&
          type == other.type &&
          coverImage == other.coverImage &&
          primaryArtists == other.primaryArtists &&
          notes == other.notes &&
          uid == other.uid &&
          projectId == other.projectId;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      trackCount.hashCode ^
      (updatedAt?.hashCode ?? 0) ^
      (releaseTitle?.hashCode ?? 0) ^
      (releaseVersion?.hashCode ?? 0) ^
      (state?.hashCode ?? 0) ^
      (type?.hashCode ?? 0) ^
      (coverImage?.hashCode ?? 0) ^
      (primaryArtists?.hashCode ?? 0) ^
      (notes?.hashCode ?? 0) ^
      (uid?.hashCode ?? 0) ^
      (projectId?.hashCode ?? 0);
}
