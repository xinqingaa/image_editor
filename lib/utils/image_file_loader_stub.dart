import 'dart:typed_data';

Future<Uint8List> readFileAsBytes(String path) {
  throw UnsupportedError('File loading is not supported on this platform.');
}

Future<String?> saveBytesToTempFile(
  Uint8List bytes, {
  String prefix = 'image',
  String extension = 'png',
}) {
  throw UnsupportedError('Saving images to a temp file is not supported on this platform.');
}


