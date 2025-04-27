import 'package:flutter/foundation.dart';
import 'package:portal/Models/product.dart';

class Project with ChangeNotifier {
  final String id;
  String name;
  String artist;
  final String notes;
  List<Product>? products;

  Project({
    required this.id,
    this.name = '',
    this.artist = '',
    this.notes = '',
    this.products,
  });

  void updateName(String newName) {
    name = newName;
    notifyListeners();
  }

  void updateArtist(String newArtist) {
    artist = newArtist;
    notifyListeners();
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['projectName'] ?? '',
      artist: map['artist'] ?? '',
      notes: map['notes'] ?? '',
      // products: not loaded in dashboard summary
    );
  }
}
