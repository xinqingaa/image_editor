// image_editor/lib/models/editor_models.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_img_editor/utils/image_loader.dart';

/// 编辑工具菜单的枚举
enum EditToolsMenu {
  none,
  cropFree,
  crop16_9,
  crop5_4,
  crop1_1,
  rotateFree,
  rotate_90,
  rotate_90_,
  text,
}

/// 图片编辑器的配置入口
class ImageEditorConfig {
  /// 是否启用裁剪工具
  final bool enableCrop;

  /// 是否启用旋转工具
  final bool enableRotate;

  /// 是否启用文本工具
  final bool enableText;

  /// 裁剪菜单中各选项的启用状态
  final CropOptionConfig cropOptions;

  /// 旋转菜单中各选项的启用状态
  final RotateOptionConfig rotateOptions;

  /// 顶部工具栏的文案与颜色配置
  final TopToolbarConfig topToolbar;

  /// 导出图片时的压缩配置
  final ImageCompressionConfig? compression;

  /// 图片编辑器配置 
  /// 
  /// [enableCrop] 是否启用裁剪工具 默认true
  /// 
  /// [enableRotate] 是否启用旋转工具 默认true
  /// 
  /// [enableText] 是否启用文本工具 默认true
  /// 
  /// [cropOptions] 裁剪选项配置
  /// 
  /// [rotateOptions] 旋转选项配置
  /// 
  /// [topToolbar] 顶部工具栏配置
  /// 
  /// [compression] 导出图片时的压缩配置
  const ImageEditorConfig({
    this.enableCrop = true,
    this.enableRotate = true,
    this.enableText = true,
    this.cropOptions = const CropOptionConfig(),
    this.rotateOptions = const RotateOptionConfig(),
    this.topToolbar = const TopToolbarConfig(),
    this.compression,
  });

  /// 是否至少启用了一个裁剪选项
  bool get hasEnabledCropOption =>
      cropOptions.enableFree ||
      cropOptions.enable16By9 ||
      cropOptions.enable5By4 ||
      cropOptions.enable1By1;
}

/// 裁剪选项配置
class CropOptionConfig {
  final bool enableFree;
  final bool enable16By9;
  final bool enable5By4;
  final bool enable1By1;

  const CropOptionConfig({
    this.enableFree = true,
    this.enable16By9 = true,
    this.enable5By4 = true,
    this.enable1By1 = true,
  });
}

/// 旋转选项配置
class RotateOptionConfig {
  /// 是否启用自由旋转（中间滑块按钮）
  final bool enableFree;
  
  /// 是否启用固定角度旋转（两侧的90度旋转按钮）
  final bool enableFixed;

  const RotateOptionConfig({
    this.enableFree = true,
    this.enableFixed = true,
  });
}

/// 顶部工具栏配置
class TopToolbarConfig {
  final String? cancelText;
  final String? titleText;
  final String? confirmText;

  final Color? cancelTextColor;
  final Color? titleTextColor;
  final Color? confirmTextColor;
  final Color? backgroundColor;
  /// 顶部工具栏配置
  /// 
  /// [cancelText] 取消按钮文本
  /// 
  /// [titleText] 标题文本
  /// 
  /// [confirmText] 确认按钮文本
  /// 
  /// [cancelTextColor] 取消按钮文本颜色
  /// 
  /// [titleTextColor] 标题文本颜色
  /// 
  /// [confirmTextColor] 确认按钮文本颜色
  /// 
  /// [backgroundColor] 背景颜色
  const TopToolbarConfig({
    this.cancelText,
    this.titleText,
    this.confirmText,
    this.cancelTextColor,
    this.titleTextColor,
    this.confirmTextColor,
    this.backgroundColor,
  });
}

/// 裁剪框拖拽控制点的枚举
enum DragHandlePosition {
  topLeft,
  topMiddle,
  topRight,
  middleLeft,
  middleRight,
  bottomLeft,
  bottomMiddle,
  bottomRight,
  inside
}

/// 代表一个文本图层的数据结构
class TextLayerData {
  String id;
  String text;
  Offset position;
  Color color;
  double fontSize;
  bool isSelected;

  TextLayerData({
    required this.id,
    this.text = '',
    Offset? position,
    this.color = Colors.white,
    this.fontSize = 32.0,
    this.isSelected = false,
  }) : position = position ?? Offset.zero; // 如果不提供位置，默认为(0,0)
}


/// 辅助函数：判断一个工具是否属于裁剪类
bool isCropTool(EditToolsMenu tool) {
  return tool == EditToolsMenu.crop1_1 ||
      tool == EditToolsMenu.cropFree ||
      tool == EditToolsMenu.crop16_9 ||
      tool == EditToolsMenu.crop5_4;
}

/// 辅助函数：判断一个工具是否属于旋转类
bool isRotateTool(EditToolsMenu tool) {
  return tool == EditToolsMenu.rotateFree ||
      tool == EditToolsMenu.rotate_90 ||
      tool == EditToolsMenu.rotate_90_;
}
