import 'package:portal/models/product.dart';
import 'package:portal/models/track.dart';

abstract class CatalogRepository {
  Future<Product?> getProduct({required String projectId, required String productId});
  Future<Product> saveProduct(Product product);
  Future<List<Track>> getTracks({required String productId});
  Future<Track> saveTrack(Track track);
  Future<void> updateTrackOrder(String productId, List<String> trackIds);
  Future<void> deleteTrack(String productId, String trackId);
  Future<void> distributeProduct(String productId);
  Future<String> generateUPC();
  Future<Map<String, dynamic>> getLabelDetails(String labelName);
}

abstract class StorageRepository {
  Future<String> uploadArtwork({required List<int> bytes, required String productId, Function(double)? onProgress});
  Future<Map<String, String>> uploadTrackAudio({required dynamic fileData, required String path, Function(double)? onProgress});
  Future<void> deleteTrackAudio(String storagePath);
}

abstract class AuthRepository {
  Future<String> getCurrentUserId();
}

abstract class LabelRepository {
  Future<List<String>> fetchLabels();
  Future<Map<String, dynamic>> getLabelDetails(String labelName);
}

abstract class ArtistRepository {
  Future<List<String>> fetchArtists();
}

abstract class SongwriterRepository {
  Future<List<String>> fetchSongwriters();
}
