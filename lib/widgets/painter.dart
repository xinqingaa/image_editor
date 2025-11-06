// image_editor/lib/widgets/painter.dart

import 'dart:math' as math;

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
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
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
      ..color = Colors.white.withValues(alpha: 0.7)
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
      // 1. 构建段落
      final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.center);
      final textStyle = ui.TextStyle(color: layer.color, fontSize: layer.fontSize);
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(layer.text);
      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: size.width));

      // 获取文本的“内在”尺寸，而不是布局容器的尺寸。
      final double intrinsicWidth = paragraph.maxIntrinsicWidth;

      // 2. 计算绘制位置
      final drawPosition = Offset(
        layer.position.dx - paragraph.width / 2,
        layer.position.dy - paragraph.height / 2,
      );

      // 3. 如果选中，绘制边框
      if (layer.id == controller.selectedTextLayerId) {
        const padding = 2.0;
        final bounds = Rect.fromCenter(
          center: layer.position,
          width: intrinsicWidth + padding,
          height: paragraph.height + padding,
        );
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        _drawDashedRect(canvas, bounds, borderPaint);
      }

      // 4. 绘制文本
      canvas.drawParagraph(paragraph, drawPosition);
    }
  }

  // [新增] 绘制虚线矩形的辅助方法
  // [已修复] 绘制虚线矩形的辅助方法
  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 4.0;
    final double totalDashLength = dashWidth + dashSpace;

    // Top line
    for (double i = rect.left; i < rect.right; i += totalDashLength) {
      canvas.drawLine(
        Offset(i, rect.top),
        // 确保终点不会超过矩形的右边界
        Offset(math.min(i + dashWidth, rect.right), rect.top),
        paint,
      );
    }
    // Bottom line
    for (double i = rect.left; i < rect.right; i += totalDashLength) {
      canvas.drawLine(
        Offset(i, rect.bottom),
        // 确保终点不会超过矩形的右边界
        Offset(math.min(i + dashWidth, rect.right), rect.bottom),
        paint,
      );
    }
    // Left line
    for (double i = rect.top; i < rect.bottom; i += totalDashLength) {
      canvas.drawLine(
        Offset(rect.left, i),
        // 确保终点不会超过矩形的下边界
        Offset(rect.left, math.min(i + dashWidth, rect.bottom)),
        paint,
      );
    }
    // Right line
    for (double i = rect.top; i < rect.bottom; i += totalDashLength) {
      canvas.drawLine(
        Offset(rect.right, i),
        // 确保终点不会超过矩形的下边界
        Offset(rect.right, math.min(i + dashWidth, rect.bottom)),
        paint,
      );
    }
  }




  @override
  bool shouldRepaint(ImageEditorPainter oldDelegate) {
    // 只有当关键状态发生变化时才重绘
    final oldController = oldDelegate.controller;
    final newController = controller;
    
    // 检查图片是否变化
    if (oldController.image != newController.image) return true;
    
    // 检查旋转角度是否变化
    if (oldController.currentRotationAngle != newController.currentRotationAngle) return true;
    
    // 检查缩放是否变化
    if ((oldController.scale - newController.scale).abs() > 0.001) return true;
    
    // 检查裁剪框是否变化
    if (oldController.cropRect != newController.cropRect) return true;
    
    // 检查工具是否变化
    if (oldController.activeTool != newController.activeTool) return true;
    
    // 检查文本图层是否变化
    if (oldController.textLayers.length != newController.textLayers.length) return true;
    if (oldController.selectedTextLayerId != newController.selectedTextLayerId) return true;
    
    // 检查文本图层内容是否变化（简化检查：只检查数量和选中状态）
    for (int i = 0; i < oldController.textLayers.length; i++) {
      final oldLayer = oldController.textLayers[i];
      final newLayer = newController.textLayers[i];
      if (oldLayer.id != newLayer.id ||
          oldLayer.text != newLayer.text ||
          oldLayer.position != newLayer.position ||
          oldLayer.color != newLayer.color ||
          (oldLayer.fontSize - newLayer.fontSize).abs() > 0.1) {
        return true;
      }
    }
    
    return false;
  }
}
