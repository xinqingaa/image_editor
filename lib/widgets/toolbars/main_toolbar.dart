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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("取消", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[200])),
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
          TextButton(
            // onPressed: () async {
            //   final resultImage = await controller.exportImage();
            //   if (resultImage != null && controller.isCroppingActive) {
            //     // 如果是裁剪操作，用新图片替换并重置状态
            //     controller.selectTool(EditToolsMenu.none); // 退出裁剪模式
            //     controller.resetTransformations(newImage: resultImage);
            //     // 这里可以选择是继续编辑还是直接返回
            //     // 按照你原来的逻辑，是直接返回
            //     Navigator.pop(context, resultImage);
            //   } else {
            //     // 其他情况（或非裁剪完成），直接返回结果
            //     Navigator.pop(context, resultImage);
            //   }
            // },
            onPressed: () async {
              // "完成"按钮现在只负责导出最终图像
              final resultImage = await controller.exportImage();
              Navigator.pop(context, resultImage);
            },
            child: const Text("导出", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
