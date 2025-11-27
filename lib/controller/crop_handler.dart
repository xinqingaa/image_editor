// image_editor/lib/controller/crop_handler.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editor_models.dart';
import '../utils/coordinate_transformer.dart';

/// 裁剪处理器
/// 负责处理所有裁剪相关的逻辑
class CropHandler {
  static const double minCropSize = 50.0;
  static const double handleTouchSize = 24.0;
  static const double handleVisualSize = 8.0;

  /// 初始化裁剪框
  static Rect initializeCropRect({
    required Size canvasSize,
    required Rect imageBounds,
    double? aspectRatio,
  }) {
    final double initialCropWidth;
    final double initialCropHeight;

    if (aspectRatio != null) {
      // 计算裁剪框尺寸，不超过图片显示区域
      double w = imageBounds.width * 0.8;
      double h = w / aspectRatio;
      if (h > imageBounds.height * 0.8) {
        h = imageBounds.height * 0.8;
        w = h * aspectRatio;
      }
      initialCropWidth = w;
      initialCropHeight = h;
    } else {
      final double maxSize = math.min(imageBounds.width, imageBounds.height) * 0.8;
      initialCropWidth = maxSize;
      initialCropHeight = maxSize;
    }

    // 将裁剪框居中在图片显示区域内
    final double left = imageBounds.left + (imageBounds.width - initialCropWidth) / 2;
    final double top = imageBounds.top + (imageBounds.height - initialCropHeight) / 2;
    return Rect.fromLTWH(left, top, initialCropWidth, initialCropHeight);
  }

  /// 执行高保真裁剪
  static Future<ui.Image?> captureHiResCroppedImage({
    required Rect cropRect,
    required Size canvasSize,
    required ui.Image image,
    required double rotationAngle,
    required double scale,
  }) async {
    // 1. 计算从"图片坐标系"到"屏幕坐标系"的变换矩阵
    final Matrix4 matrixToScreen = CoordinateTransformer.createImageToScreenMatrix(
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );

    // 2. 求逆矩阵，得到从"屏幕坐标系"返回"图片坐标系"的变换
    final Matrix4 screenToImageMatrix = Matrix4.inverted(matrixToScreen);

    // 3. 将屏幕上的裁剪框的四个角，通过逆矩阵变换回图片上的坐标
    final topLeft = MatrixUtils.transformPoint(screenToImageMatrix, cropRect.topLeft);
    final topRight = MatrixUtils.transformPoint(screenToImageMatrix, cropRect.topRight);
    final bottomLeft = MatrixUtils.transformPoint(screenToImageMatrix, cropRect.bottomLeft);
    final bottomRight = MatrixUtils.transformPoint(screenToImageMatrix, cropRect.bottomRight);

    // 4. 计算能完全包围这四个点的、在图片坐标系中的矩形边界 (sourceRect)
    final double minX = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx].reduce(math.min);
    final double maxX = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx].reduce(math.max);
    final double minY = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy].reduce(math.min);
    final double maxY = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy].reduce(math.max);

    final Rect sourceRect = Rect.fromLTRB(minX, minY, maxX, maxY);

    // 5. 计算新图片的尺寸（高保真尺寸）
    final int newWidth = sourceRect.width.round();
    final int newHeight = sourceRect.height.round();

    if (newWidth <= 0 || newHeight <= 0) return null;

    // 6. 使用 PictureRecorder 和 drawImageRect 进行高保真绘制
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()));

    final paint = Paint()..filterQuality = FilterQuality.high;
    final Rect destinationRect = Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble());

    // 核心：从原图的 sourceRect 区域，绘制到新画布的 destinationRect 区域
    canvas.drawImageRect(image, sourceRect, destinationRect, paint);

    // 7. 生成最终的高清图片
    final picture = recorder.endRecording();
    return await picture.toImage(newWidth, newHeight);
  }

  /// 将裁剪框限制在旋转后图片的实际显示边界内
  /// 考虑旋转后图片边界是斜边的情况
  static Rect clampRectToImageBounds({
    required Rect rect,
    required Rect imageBounds,
    required double rotationAngle,
    required Size canvasSize,
    required double scale,
    required ui.Image image,
  }) {
    // 如果图片没有旋转，使用简单的轴对齐边界检查
    if (rotationAngle == 0.0) {
      double width = rect.width.clamp(minCropSize, imageBounds.width);
      double height = rect.height.clamp(minCropSize, imageBounds.height);
      double left = rect.left.clamp(imageBounds.left, imageBounds.right - rect.width);
      double top = rect.top.clamp(imageBounds.top, imageBounds.bottom - rect.height);

      if (left + width > imageBounds.right) {
        left = imageBounds.right - width;
      }
      if (top + height > imageBounds.bottom) {
        top = imageBounds.bottom - height;
      }
      if (left < imageBounds.left) left = imageBounds.left;
      if (top < imageBounds.top) top = imageBounds.top;

      return Rect.fromLTWH(left, top, width, height);
    }

    // 图片有旋转，需要检查裁剪框的四个角是否都在图片内
    // 辅助函数：检查给定尺寸和位置的裁剪框是否完全在图片内
    bool isCropRectInside(Rect testRect) {
      final List<Offset> corners = [
        Offset(testRect.left, testRect.top),
        Offset(testRect.right, testRect.top),
        Offset(testRect.left, testRect.bottom),
        Offset(testRect.right, testRect.bottom),
      ];
      return corners.every((corner) => CoordinateTransformer.isPointInsideRotatedImage(
        screenPoint: corner,
        canvasSize: canvasSize,
        rotationAngle: rotationAngle,
        scale: scale,
        image: image,
      ));
    }

    // 先尝试直接使用传入的 rect，如果完全在图片内，直接返回
    if (isCropRectInside(rect)) {
      return rect;
    }

    // 如果不在图片内，先尝试限制在 imageBounds 内（轴对齐边界框）
    double left = rect.left.clamp(imageBounds.left, imageBounds.right - rect.width);
    double top = rect.top.clamp(imageBounds.top, imageBounds.bottom - rect.height);
    double width = rect.width.clamp(minCropSize, imageBounds.width);
    double height = rect.height.clamp(minCropSize, imageBounds.height);

    if (left + width > imageBounds.right) {
      left = imageBounds.right - width;
    }
    if (top + height > imageBounds.bottom) {
      top = imageBounds.bottom - height;
    }
    if (left < imageBounds.left) left = imageBounds.left;
    if (top < imageBounds.top) top = imageBounds.top;

    Rect clampedRect = Rect.fromLTWH(left, top, width, height);

    // 检查限制后的矩形是否在图片内
    if (isCropRectInside(clampedRect)) {
      return clampedRect;
    }

    // 如果仍然不在图片内，需要调整位置和尺寸
    // 保持裁剪框中心不变，使用二分法找到最大可用的尺寸
    final double centerX = clampedRect.left + clampedRect.width / 2;
    final double centerY = clampedRect.top + clampedRect.height / 2;

    double minWidth = minCropSize;
    double minHeight = minCropSize;
    double maxWidth = clampedRect.width;
    double maxHeight = clampedRect.height;

    // 二分查找最大可用尺寸
    const int maxIterations = 30;
    for (int i = 0; i < maxIterations; i++) {
      final double testWidth = (minWidth + maxWidth) / 2;
      final double testHeight = (minHeight + maxHeight) / 2;

      final Rect testRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: testWidth,
        height: testHeight,
      );

      if (isCropRectInside(testRect)) {
        // 如果完全在图片内，尝试增大尺寸
        minWidth = testWidth;
        minHeight = testHeight;
      } else {
        // 如果有角在图片外，缩小尺寸
        maxWidth = testWidth;
        maxHeight = testHeight;
      }

      // 如果尺寸差异很小，停止迭代
      if ((maxWidth - minWidth) < 1.0 && (maxHeight - minHeight) < 1.0) {
        break;
      }
    }

    width = minWidth;
    height = minHeight;
    left = centerX - width / 2;
    top = centerY - height / 2;

    // 如果当前尺寸和位置仍然有角在图片外，尝试微调位置
    Rect currentRect = Rect.fromLTWH(left, top, width, height);
    if (!isCropRectInside(currentRect)) {
      // 尝试在图片边界框内搜索最佳位置
      final double searchStep = math.min(width, height) / 5;
      double bestLeft = left;
      double bestTop = top;
      int bestInsideCount = 0;

      for (double dx = -imageBounds.width / 2; dx <= imageBounds.width / 2; dx += searchStep) {
        for (double dy = -imageBounds.height / 2; dy <= imageBounds.height / 2; dy += searchStep) {
          final double testLeft = imageBounds.center.dx - width / 2 + dx;
          final double testTop = imageBounds.center.dy - height / 2 + dy;
          final Rect testRect = Rect.fromLTWH(testLeft, testTop, width, height);

          if (isCropRectInside(testRect)) {
            // 找到完全在图片内的位置
            return testRect;
          }

          // 计算在图片内的角的数量
          final List<Offset> corners = [
            Offset(testLeft, testTop),
            Offset(testLeft + width, testTop),
            Offset(testLeft, testTop + height),
            Offset(testLeft + width, testTop + height),
          ];
          final int insideCount = corners.where((corner) => CoordinateTransformer.isPointInsideRotatedImage(
            screenPoint: corner,
            canvasSize: canvasSize,
            rotationAngle: rotationAngle,
            scale: scale,
            image: image,
          )).length;

          if (insideCount > bestInsideCount) {
            bestInsideCount = insideCount;
            bestLeft = testLeft;
            bestTop = testTop;
          }
        }
      }

      // 如果找到了更好的位置，使用它
      if (bestInsideCount > 0) {
        left = bestLeft;
        top = bestTop;
      } else {
        // 如果找不到合适的位置，进一步缩小尺寸
        width = math.min(width, imageBounds.width * 0.8);
        height = math.min(height, imageBounds.height * 0.8);
        width = width.clamp(minCropSize, imageBounds.width);
        height = height.clamp(minCropSize, imageBounds.height);
        left = imageBounds.center.dx - width / 2;
        top = imageBounds.center.dy - height / 2;
      }
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  /// 获取当前工具的宽高比
  static double? getAspectRatio(EditToolsMenu tool) {
    switch (tool) {
      case EditToolsMenu.crop16_9:
        return 16.0 / 9.0;
      case EditToolsMenu.crop5_4:
        return 5.0 / 4.0;
      case EditToolsMenu.crop1_1:
        return 1.0;
      default:
        return null;
    }
  }
}

