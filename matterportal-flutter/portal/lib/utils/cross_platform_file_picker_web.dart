import 'package:universal_html/html.dart' as html;

Future<void> pickWavFilesWeb(Function(dynamic) handleFile) async {
  html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.wav';
  uploadInput.multiple = true;
  uploadInput.click();
  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null) {
      for (var file in files) {
        handleFile(file);
      }
    }
  });
}
