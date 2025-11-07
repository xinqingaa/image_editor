import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readFileAsBytes(String path) async {
  return await File(path).readAsBytes();
}

