import 'package:cloud_firestore/cloud_firestore.dart';

class Seller {
  final String id;
  final String name;
  final String avatarUrl;
  final String bio;
  final double rating;
  final String location;
  final DateTime memberSince;

  Seller({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.rating,
    required this.location,
    required this.memberSince,
  });

  factory Seller.fromFirestore(Map<String, dynamic> data, String id) {
    return Seller(
      id: id,
      name: data['name'] ?? 'Anonymous Seller',
      avatarUrl: data['avatarUrl'] ?? '',
      bio: data['bio'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      location: data['location'] ?? '',
      memberSince: (data['memberSince'] as Timestamp).toDate(),
    );
  }

  static Seller empty() => Seller(
        id: '',
        name: 'Unknown Seller',
        avatarUrl: '',
        bio: '',
        rating: 0.0,
        location: '',
        memberSince: DateTime.now(),
      );
}
