import 'cross_platform_file_picker_stub.dart'
  if (dart.library.html) 'cross_platform_file_picker_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

typedef PickedFileHandler = Future<void> Function(dynamic file);

Future<void> pickWavFiles(PickedFileHandler handleFile) async {
  if (kIsWeb) {
    await pickWavFilesWeb(handleFile);
  } else {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
      allowMultiple: true,
    );
    if (result != null) {
      for (var file in result.files) {
        await handleFile(file);
      }
    }
  }
}
