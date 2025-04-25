abstract class StorageRepository {
  Future<String> uploadArtwork({required List<int> bytes, required String productId, Function(double)? onProgress});
  Future<Map<String, String>> uploadTrackAudio({required dynamic fileData, required String path, Function(double)? onProgress});
  Future<void> deleteTrackAudio(String storagePath);
}
