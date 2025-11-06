// image_editor/lib/widgets/toolbars/main_toolbar.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';

class MainToolbar extends StatelessWidget {
  final ImageEditorController controller;

  const MainToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.activeTool != EditToolsMenu.none) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child:  Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.refresh, color: controller.canResetToOriginal ? Colors.white : Colors.grey[600]),
            onPressed: controller.canResetToOriginal ? () => controller.resetToOriginal() : null,
            tooltip: '撤销（重置到原始状态）',
          ),
          _buildToolButton(
            context,
            tool: EditToolsMenu.cropFree,
            icon: Icons.crop,
            isActive: isCropTool(controller.activeTool),
          ),
          _buildToolButton(
            context,
            tool: EditToolsMenu.rotateFree,
            icon: Icons.crop_rotate_sharp,
            isActive: isRotateTool(controller.activeTool),
          ),
          _buildToolButton(
            context,
            tool: EditToolsMenu.text,
            icon: Icons.text_fields,
            isActive: controller.activeTool == EditToolsMenu.text,
          ),
          IconButton(
            icon: Icon(Icons.undo, color: controller.canUndo ? Colors.white : Colors.grey[600]),
            onPressed: controller.canUndo ? () => controller.undoLastOperation() : null,
            tooltip: '回退（撤销上一次操作）',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, {required EditToolsMenu tool, required IconData icon, required bool isActive}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () => controller.selectTool(tool),
        ),
        // 由于现在展开子菜单时 关闭了主菜单 所以选中标志看不到
        if (isActive)
          Positioned(
            bottom: -2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
      ],
    );
  }
}
