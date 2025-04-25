abstract class LabelRepository {
  Future<List<String>> fetchLabels();
  Future<Map<String, dynamic>> getLabelDetails(String labelName);
}
