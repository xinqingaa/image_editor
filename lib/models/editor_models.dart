// image_editor/lib/models/editor_models.dart
import 'dart:ui';
import 'package:flutter/material.dart';

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
