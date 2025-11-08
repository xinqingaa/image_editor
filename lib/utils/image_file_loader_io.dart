import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<Uint8List> readFileAsBytes(String path) async {
  return await File(path).readAsBytes();
}

Future<String?> saveBytesToTempFile(
  Uint8List bytes, {
  String prefix = 'image',
  String extension = 'png',
}) async {
  final Directory directory = await getTemporaryDirectory();
  final String sanitizedExtension = extension.replaceAll('.', '');
  final String safeExtension = sanitizedExtension.isEmpty ? 'tmp' : sanitizedExtension;
  final String safePrefix = prefix.isEmpty ? 'image' : prefix;
  final String filePath =
      '${directory.path}/${safePrefix}_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
  final File file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

