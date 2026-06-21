import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class AppUtils {
  static Future<String?> pickAndSaveImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      
      final appDocDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(p.join(appDocDir.path, 'images'));
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final extension = p.extension(sourceFile.path);
      final fileName = '${const Uuid().v4()}$extension';
      final destinationPath = p.join(imagesDir.path, fileName);
      
      await sourceFile.copy(destinationPath);
      return destinationPath;
    }
    return null;
  }
}
