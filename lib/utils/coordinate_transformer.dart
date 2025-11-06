// image_editor/lib/utils/coordinate_transformer.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 坐标变换工具类
/// 提供图片坐标系和屏幕坐标系之间的转换功能
class CoordinateTransformer {
  /// 计算从图片坐标系到屏幕坐标系的变换矩阵
  static Matrix4 createImageToScreenMatrix({
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required ui.Image image,
  }) {
    final Matrix4 matrix = Matrix4.identity();
    matrix.translate(canvasSize.width / 2, canvasSize.height / 2);
    matrix.rotateZ(rotationAngle);
    matrix.scale(scale, scale);
    matrix.translate(-image.width / 2, -image.height / 2);
    return matrix;
  }

  /// 计算从屏幕坐标系到图片坐标系的变换矩阵（逆变换）
  static Matrix4 createScreenToImageMatrix({
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required ui.Image image,
  }) {
    final Matrix4 imageToScreen = createImageToScreenMatrix(
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );
    return Matrix4.inverted(imageToScreen);
  }

  /// 将屏幕坐标转换为图片坐标
  static Offset screenToImage({
    required Offset screenPoint,
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required ui.Image image,
  }) {
    final Matrix4 screenToImageMatrix = createScreenToImageMatrix(
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );
    return MatrixUtils.transformPoint(screenToImageMatrix, screenPoint);
  }

  /// 将图片坐标转换为屏幕坐标
  static Offset imageToScreen({
    required Offset imagePoint,
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required ui.Image image,
  }) {
    final Matrix4 imageToScreenMatrix = createImageToScreenMatrix(
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );
    return MatrixUtils.transformPoint(imageToScreenMatrix, imagePoint);
  }

  /// 计算旋转后图片在屏幕上的实际显示边界框
  static Rect getImageDisplayBounds({
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required ui.Image image,
  }) {
    // 图片的四个角在图片坐标系中的坐标
    final double halfWidth = image.width / 2;
    final double halfHeight = image.height / 2;
    final List<Offset> imageCorners = [
      Offset(-halfWidth, -halfHeight), // 左上
      Offset(halfWidth, -halfHeight),  // 右上
      Offset(-halfWidth, halfHeight),  // 左下
      Offset(halfWidth, halfHeight),   // 右下
    ];

    // 构建从图片坐标系到屏幕坐标系的变换矩阵
    final Matrix4 imageToScreenMatrix = createImageToScreenMatrix(
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );

    // 将图片的四个角变换到屏幕坐标系
    final List<Offset> screenCorners = imageCorners.map((corner) {
      return MatrixUtils.transformPoint(imageToScreenMatrix, corner);
    }).toList();

    // 计算边界框
    final double minX = screenCorners.map((p) => p.dx).reduce(math.min);
    final double maxX = screenCorners.map((p) => p.dx).reduce(math.max);
    final double minY = screenCorners.map((p) => p.dy).reduce(math.min);
    final double maxY = screenCorners.map((p) => p.dy).reduce(math.max);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 检查一个点是否在旋转后的图片内
  static bool isPointInsideRotatedImage({
    required Offset screenPoint,
    required Size canvasSize,
    required double rotationAngle,
    required double scale,
    required ui.Image image,
  }) {
    final Offset imagePoint = screenToImage(
      screenPoint: screenPoint,
      canvasSize: canvasSize,
      rotationAngle: rotationAngle,
      scale: scale,
      image: image,
    );

    // 检查点是否在图片的原始矩形内
    final double halfWidth = image.width / 2;
    final double halfHeight = image.height / 2;
    return imagePoint.dx >= -halfWidth &&
           imagePoint.dx <= halfWidth &&
           imagePoint.dy >= -halfHeight &&
           imagePoint.dy <= halfHeight;
  }
}

