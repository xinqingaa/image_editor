// image_editor/lib/widgets/toolbars/active_tool_menu.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';
import 'crop_toolbar.dart';
import 'rotate_toolbar.dart';

/// 这个Widget根据控制器中当前激活的工具，动态显示对应的子菜单
class ActiveToolMenu extends StatelessWidget {
  final ImageEditorController controller;

  const ActiveToolMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (isCropTool(controller.activeTool)) {
      return CropToolbar(controller: controller);
    }
    if (isRotateTool(controller.activeTool)) {
      return RotateToolbar(controller: controller);
    }
    // if (controller.activeTool == EditToolsMenu.text) {
    //   return TextToolbar(controller: controller); // 文本工具栏可以类似地创建
    // }
    return const SizedBox.shrink(); // 没有激活的子菜单时返回空SizedBox
  }
}
