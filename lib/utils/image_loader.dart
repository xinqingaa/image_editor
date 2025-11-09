import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'image_file_loader_stub.dart'
    if (dart.library.io) 'image_file_loader_io.dart';

class ImageCompressionConfig {
  /// 图片压缩配置
  /// 
  /// [enabled] 是否启用压缩 默认true
  /// 
  /// [scale] 压缩比例，0-1，默认0.5
  /// 
  /// [format] 压缩格式，默认png
  const ImageCompressionConfig({
    this.enabled = true,
    this.scale = 0.5,
    this.format = ui.ImageByteFormat.png,
  }) : assert(scale == null || scale > 0, 'scale 必须大于 0');

  final bool enabled;
  final double? scale; // 0-1 缩放因子
  final ui.ImageByteFormat format;
}

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
  ImageCompressionConfig? compression,
}) async {
  final ImageCompressionConfig effectiveConfig =
      compression ?? const ImageCompressionConfig();

  final double scale = effectiveConfig.scale ?? 1.0;
  ui.Image targetImage = image;
  ui.Image? resizedImage;

  if (effectiveConfig.enabled && scale > 0 && scale < 1.0) {
    final int targetWidth = math.max(1, (image.width * scale).round());
    final int targetHeight = math.max(1, (image.height * scale).round());
    if (targetWidth != image.width || targetHeight != image.height) {
      resizedImage = await _resizeImage(image, targetWidth, targetHeight);
      targetImage = resizedImage;
    }
  }

  final ByteData? byteData =
      await targetImage.toByteData(format: effectiveConfig.format);

  if (resizedImage != null) {
    _disposeImage(resizedImage);
  }

  if (byteData == null) {
    return null;
  }
  return byteData.buffer.asUint8List();
}

/// 将 [ui.Image] 写入临时目录并返回路径字符串（仅原生平台可用）
Future<String?> saveImageToTempFile(
  ui.Image image, {
  ImageCompressionConfig? compression,
  String prefix = 'image',
}) async {
  final ImageCompressionConfig effectiveConfig =
      compression ?? const ImageCompressionConfig();
  final Uint8List? bytes =
      await convertUiImageToBytes(image, compression: effectiveConfig);
  if (bytes == null) {
    return null;
  }
  final String extension = _fileExtensionForFormat(effectiveConfig.format);
  return saveBytesToTempFile(bytes, prefix: prefix, extension: extension);
}

String _fileExtensionForFormat(ui.ImageByteFormat format) {
  return format == ui.ImageByteFormat.png ? 'png' : 'raw';
}

Future<ui.Image> _resizeImage(
  ui.Image source,
  int targetWidth,
  int targetHeight,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  final ui.Rect srcRect = ui.Rect.fromLTWH(
    0,
    0,
    source.width.toDouble(),
    source.height.toDouble(),
  );
  final ui.Rect dstRect = ui.Rect.fromLTWH(
    0,
    0,
    targetWidth.toDouble(),
    targetHeight.toDouble(),
  );
  final ui.Paint paint = ui.Paint()..filterQuality = ui.FilterQuality.high;

  canvas.drawImageRect(source, srcRect, dstRect, paint);

  final ui.Picture picture = recorder.endRecording();
  try {
    final ui.Image resized =
        await picture.toImage(targetWidth, targetHeight);
    return resized;
  } finally {
    picture.dispose();
  }
}

void _disposeImage(ui.Image image) {
  try {
    image.dispose();
  } catch (_) {
    // ignore: deprecated_member_use，用于兼容旧版 Flutter
  }
}
