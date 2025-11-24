// image_editor/lib/widgets/toolbars/rotate_toolbar.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';
import 'free_rotate_slider.dart';

class RotateToolbar extends StatelessWidget {
  final ImageEditorController controller;

  const RotateToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool isFreeRotateActive = controller.activeTool == EditToolsMenu.rotateFree && controller.isFreeRotateEnabled;
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          if (isFreeRotateActive)
            FreeRotateSlider(
              initialAngle: 0.0,
              onAngleChanged: (degrees) {
                controller.updateFreeRotation(degrees);
              },
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 固定角度旋转按钮（左侧 - 逆时针90°）
                if (controller.isFixedRotateEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton(
                      tooltip: "逆时针90°",
                      icon: Icon(CupertinoIcons.rotate_left, color: Colors.white),
                      highlightColor: Colors.grey[800],
                      onPressed: () => controller.rotate(-90),
                    ),
                  ),
                // 自由旋转按钮（中间）
                if (controller.isFreeRotateEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton(
                      tooltip: "自由旋转",
                      icon: Icon(Icons.rotate_left_outlined, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: controller.activeTool == EditToolsMenu.rotateFree ? Colors.grey[800] : Colors.transparent,
                      ),
                      onPressed: () {
                        controller.selectTool(EditToolsMenu.rotateFree);
                      },
                    ),
                  ),
                // 固定角度旋转按钮（右侧 - 顺时针90°）
                if (controller.isFixedRotateEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton(
                      tooltip: "顺时针90°",
                      icon: Icon(CupertinoIcons.rotate_right, color: Colors.white),
                      highlightColor: Colors.grey[800],
                      onPressed: () => controller.rotate(90),
                    ),
                  ),
              ],
            ),
          )
        ],
      )
    );
  }
}
