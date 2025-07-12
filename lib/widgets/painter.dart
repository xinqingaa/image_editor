// image_editor/lib/widgets/painter.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../controller/image_editor_controller.dart';

class ImageEditorPainter extends CustomPainter {
  final ImageEditorController controller;

  ImageEditorPainter({required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    final image = controller.image;
    final rotationAngle = controller.currentRotationAngle;
    final scale = controller.scale;
    final cropRect = controller.cropRect;
    final isCropping = controller.isCroppingActive;
    final handleSize = controller.handleVisualSize;

    final paint = Paint();

    // --- 1. 绘制变换后的图片 ---
    final canvasCenterX = size.width / 2;
    final canvasCenterY = size.height / 2;
    canvas.save();
    canvas.translate(canvasCenterX, canvasCenterY);
    canvas.rotate(rotationAngle);
    canvas.scale(scale, scale);
    canvas.drawImage(image, Offset(-image.width / 2, -image.height / 2), paint);
    canvas.restore();

    // --- 2. 如果裁剪激活，则绘制裁剪UI ---
    if (isCropping && cropRect != null) {
      _drawCropUI(canvas, size, cropRect, handleSize);
    }


    // --- [新增] 3. 绘制所有文本图层 ---
    _drawTextLayers(canvas, size);
  }

  void _drawCropUI(Canvas canvas, Size size, Rect currentCropRect, double handleRadius) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.7);
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final handlePaint = Paint()..color = Colors.white;

    Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(currentCropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    canvas.drawRect(currentCropRect, borderPaint);

    const int gridLines = 2;
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= gridLines; i++) {
      double x = currentCropRect.left + currentCropRect.width * i / (gridLines + 1);
      double y = currentCropRect.top + currentCropRect.height * i / (gridLines + 1);
      canvas.drawLine(Offset(x, currentCropRect.top), Offset(x, currentCropRect.bottom), gridPaint);
      canvas.drawLine(Offset(currentCropRect.left, y), Offset(currentCropRect.right, y), gridPaint);
    }

    canvas.drawCircle(currentCropRect.topLeft, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.topCenter, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.topRight, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.centerLeft, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.centerRight, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.bottomLeft, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.bottomCenter, handleRadius, handlePaint);
    canvas.drawCircle(currentCropRect.bottomRight, handleRadius, handlePaint);
  }


  // [新增] 绘制文本图层的辅助方法
  void _drawTextLayers(Canvas canvas, Size size) {

    for (final layer in controller.textLayers) {
      // 1. 创建段落样式
      final paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: layer.fontSize,
      );

      // 2. 创建文本样式
      final textStyle = ui.TextStyle(
        color: layer.color,
        fontSize: layer.fontSize,
        // 你可以在这里添加更多样式，如字体、粗细等
      );

      // 3. 构建段落
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(layer.text);

      final paragraph = paragraphBuilder.build();

      // 4. 布局段落，宽度不限
      paragraph.layout(ui.ParagraphConstraints(width: size.width));

      // 5. 计算绘制位置
      // 我们希望 layer.position 是文本的中心点
      final Offset drawPosition = Offset(
        layer.position.dx - paragraph.width / 2,
        layer.position.dy - paragraph.height / 2,
      );

      // 6. 绘制段落到画布
      canvas.drawParagraph(paragraph, drawPosition);
    }
  }



  @override
  bool shouldRepaint(ImageEditorPainter oldDelegate) {
    // 因为UI是响应式地根据controller重建的，所以总是重绘是最安全和简单的
    return true;
  }
}
