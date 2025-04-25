import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String projectName;
  final String projectArtist;
  final String uid;
  final String notes;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.projectName,
    required this.projectArtist,
    required this.uid,
    required this.notes,
    this.updatedAt,
  });

  factory Project.fromMap(Map<String, dynamic> map, String id) {
    return Project(
      id: id,
      projectName: map['projectName'] ?? '',
      projectArtist: map['projectArtist'] ?? '',
      uid: map['uid'] ?? '',
      notes: map['notes'] ?? '',
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'projectArtist': projectArtist,
      'uid': uid,
      'notes': notes,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get name => projectName;
}
