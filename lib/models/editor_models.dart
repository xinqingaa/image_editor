// image_editor/lib/models/editor_models.dart

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
