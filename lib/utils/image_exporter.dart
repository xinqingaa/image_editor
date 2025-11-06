// image_editor/lib/utils/image_exporter.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editor_models.dart';
import 'coordinate_transformer.dart';

/// 图片导出器
/// 负责将编辑后的图片导出为高清晰度的最终图片
class ImageExporter {
  /// 捕获当前所有变换（旋转、缩放、平移）后的最终图像
  /// 使用原图像素尺寸保持高清晰度
  static Future<ui.Image> captureTransformedImage({
    required ui.Image image,
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required List<TextLayerData> textLayers,
  }) async {
    // 1. 计算旋转后图片的边界框尺寸（使用原图像素尺寸）
    final sinAngle = math.sin(rotationAngle).abs();
    final cosAngle = math.cos(rotationAngle).abs();
    final rotatedWidth = image.width * cosAngle + image.height * sinAngle;
    final rotatedHeight = image.width * sinAngle + image.height * cosAngle;

    // 2. 计算屏幕到像素的缩放比例
    // 屏幕上的图片尺寸 = 原图尺寸 * scale
    // 所以像素坐标 = 屏幕坐标 / scale
    final double pixelScale = 1.0 / scale;

    // 3. 计算导出画布的尺寸（使用原图像素尺寸）
    final int exportWidth = rotatedWidth.round();
    final int exportHeight = rotatedHeight.round();

    // 4. 创建高分辨率画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, exportWidth.toDouble(), exportHeight.toDouble()));

    // 5. 绘制变换后的图片（使用高保真绘制）
    final paint = Paint()..filterQuality = FilterQuality.high;
    final canvasCenterX = exportWidth / 2;
    final canvasCenterY = exportHeight / 2;
    canvas.save();
    canvas.translate(canvasCenterX, canvasCenterY);
    canvas.rotate(rotationAngle);
    // 注意：这里不应用scale，因为我们已经在像素坐标系中
    canvas.drawImage(image, Offset(-image.width / 2, -image.height / 2), paint);
    canvas.restore();

    // 6. 绘制所有文本图层（需要将屏幕坐标转换为像素坐标）
    // 计算从图片坐标系到屏幕坐标系的变换矩阵
    final Matrix4 imageToScreenMatrix = CoordinateTransformer.createImageToScreenMatrix(
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );
    // 求逆矩阵，得到从屏幕坐标系到图片坐标系的变换
    final Matrix4 screenToImageMatrix = Matrix4.inverted(imageToScreenMatrix);

    // 计算从图片坐标系到导出画布坐标系的变换矩阵
    final Matrix4 imageToExportMatrix = Matrix4.identity();
    imageToExportMatrix.translate(exportWidth / 2, exportHeight / 2);
    imageToExportMatrix.rotateZ(rotationAngle);
    imageToExportMatrix.translate(-image.width / 2, -image.height / 2);

    for (final layer in textLayers) {
      // 创建段落样式
      final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.center);
      // 创建文本样式（字体大小也需要按比例缩放）
      final textStyle = ui.TextStyle(
        color: layer.color,
        fontSize: layer.fontSize * pixelScale,
      );
      // 构建段落
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(layer.text);
      final paragraph = paragraphBuilder.build();
      // 布局段落（使用像素尺寸）
      paragraph.layout(ui.ParagraphConstraints(width: exportWidth.toDouble()));

      // 将屏幕坐标转换为图片坐标，再转换为导出画布坐标
      final imagePos = MatrixUtils.transformPoint(screenToImageMatrix, layer.position);
      final exportPos = MatrixUtils.transformPoint(imageToExportMatrix, imagePos);

      // 计算绘制位置
      final Offset textDrawPosition = Offset(
        exportPos.dx - paragraph.width / 2,
        exportPos.dy - paragraph.height / 2,
      );
      // 将文本绘制到导出用的 Canvas 上
      canvas.drawParagraph(paragraph, textDrawPosition);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(exportWidth, exportHeight);
  }
}

