// image_editor/lib/controller/rotation_handler.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 旋转处理器
/// 负责处理所有旋转相关的逻辑
class RotationHandler {
  /// 渲染一个只包含旋转变换的新图片
  static Future<ui.Image> renderRotatedImage({
    required ui.Image image,
    required double angle,
  }) async {
    // 计算旋转后新图片的边界框大小
    final sinAngle = math.sin(angle).abs();
    final cosAngle = math.cos(angle).abs();
    final newWidth = image.width * cosAngle + image.height * sinAngle;
    final newHeight = image.width * sinAngle + image.height * cosAngle;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, newWidth, newHeight));

    // 将画布原点移动到新画布中心
    canvas.translate(newWidth / 2, newHeight / 2);
    // 旋转
    canvas.rotate(angle);
    // 将图片中心对齐到原点并绘制
    canvas.drawImage(image, Offset(-image.width / 2, -image.height / 2), Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(newWidth.round(), newHeight.round());
  }

  /// 计算旋转后图片的边界框尺寸
  static Size calculateRotatedBounds({
    required ui.Image image,
    required double angle,
  }) {
    final sinAngle = math.sin(angle).abs();
    final cosAngle = math.cos(angle).abs();
    final width = image.width * cosAngle + image.height * sinAngle;
    final height = image.width * sinAngle + image.height * cosAngle;
    return Size(width, height);
  }
}

