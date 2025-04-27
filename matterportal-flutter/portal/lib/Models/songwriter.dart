import 'package:cloud_firestore/cloud_firestore.dart';

class Songwriter {
  final String id;
  final String name;
  final String? email;
  final DateTime? createdAt;

  Songwriter({
    required this.id,
    required this.name,
    this.email,
    this.createdAt,
  });

  // Create from Firestore document
  factory Songwriter.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Songwriter(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map (for stream-based data)
  factory Songwriter.fromMap(Map<String, dynamic> map) {
    return Songwriter(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : null),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create a copy of the songwriter with some fields updated
  Songwriter copyWith({
    String? name,
    String? email,
  }) {
    return Songwriter(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }
} 