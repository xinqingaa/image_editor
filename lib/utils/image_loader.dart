import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'image_file_loader_stub.dart'
    if (dart.library.io) 'image_file_loader_io.dart';

/// 将 [Uint8List] 解码为 [ui.Image]
Future<ui.Image> decodeImageFromBytes(Uint8List bytes) {
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

/// 从 assets 加载图片并解码为 [ui.Image]
Future<ui.Image> loadImageFromAssets(
  String assetPath, {
  AssetBundle? bundle,
}) async {
  final ByteData data = await (bundle ?? rootBundle).load(assetPath);
  return decodeImageFromBytes(data.buffer.asUint8List());
}

/// 从文件系统加载图片（不支持 Web 平台）
Future<ui.Image> loadImageFromFile(String path) async {
  final Uint8List bytes = await readFileAsBytes(path);
  return decodeImageFromBytes(bytes);
}

/// 通过网络请求加载图片
Future<ui.Image> loadImageFromNetwork(
  String url, {
  http.Client? client,
  Map<String, String>? headers,
}) async {
  final http.Client effectiveClient = client ?? http.Client();
  try {
    final http.Response response =
        await effectiveClient.get(Uri.parse(url), headers: headers);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', Uri.parse(url));
    }
    return decodeImageFromBytes(response.bodyBytes);
  } finally {
    if (client == null) {
      effectiveClient.close();
    }
  }
}

/// 将 [ui.Image] 转换为 [Uint8List]，默认输出 PNG
Future<Uint8List?> convertUiImageToBytes(
  ui.Image image, {
  ui.ImageByteFormat format = ui.ImageByteFormat.png,
}) async {
  final ByteData? byteData = await image.toByteData(format: format);
  if (byteData == null) {
    return null;
  }
  return byteData.buffer.asUint8List();
}

/// 将 [ui.Image] 写入临时目录并返回路径字符串（仅原生平台可用）
Future<String?> saveImageToTempFile(
  ui.Image image, {
  ui.ImageByteFormat format = ui.ImageByteFormat.png,
  String prefix = 'image',
}) async {
  final Uint8List? bytes = await convertUiImageToBytes(image, format: format);
  if (bytes == null) {
    return null;
  }
  final String extension = _fileExtensionForFormat(format);
  return saveBytesToTempFile(bytes, prefix: prefix, extension: extension);
}

String _fileExtensionForFormat(ui.ImageByteFormat format) {
  return format == ui.ImageByteFormat.png ? 'png' : 'raw';
}
