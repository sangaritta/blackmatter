import 'package:cloud_firestore/cloud_firestore.dart';

class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final String? spotifyUrl;
  final String? appleMusicUrl;
  final String? youtubeUrl;
  final String? soundcloudUrl;
  final String? tiktokUrl;
  final String? instagramURL;
  final String? facebookUrl;
  final String? xUrl;
  final DateTime? createdAt;
  final bool isFavorite;

  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.spotifyUrl,
    this.appleMusicUrl,
    this.youtubeUrl,
    this.soundcloudUrl,
    this.tiktokUrl,
    this.instagramURL,
    this.facebookUrl,
    this.xUrl,
    this.createdAt,
    this.isFavorite = false,
  });

  factory Artist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Artist(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      spotifyUrl: data['spotifyUrl'],
      appleMusicUrl: data['appleMusicUrl'],
      youtubeUrl: data['youtubeUrl'],
      soundcloudUrl: data['soundcloudUrl'],
      tiktokUrl: data['tiktokUrl'],
      instagramURL: data['instagramURL'],
      facebookUrl: data['facebookUrl'],
      xUrl: data['xUrl'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isFavorite: data['favorite'] == true,
    );
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      spotifyUrl: map['spotifyUrl'],
      appleMusicUrl: map['appleMusicUrl'],
      youtubeUrl: map['youtubeUrl'],
      soundcloudUrl: map['soundcloudUrl'],
      tiktokUrl: map['tiktokUrl'],
      instagramURL: map['instagramURL'],
      facebookUrl: map['facebookUrl'],
      xUrl: map['xUrl'],
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : null),
      isFavorite: map['favorite'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'spotifyUrl': spotifyUrl,
      'appleMusicUrl': appleMusicUrl,
      'youtubeUrl': youtubeUrl,
      'soundcloudUrl': soundcloudUrl,
      'tiktokUrl': tiktokUrl,
      'instagramURL': instagramURL,
      'facebookUrl': facebookUrl,
      'xUrl': xUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'favorite': isFavorite,
    };
  }
}
