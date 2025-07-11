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
    final bool isFreeRotateActive = controller.activeTool == EditToolsMenu.rotateFree;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child:IconButton(
                  tooltip: "逆时针90°",
                  icon: Icon(CupertinoIcons.rotate_left, color: Colors.white),
                  highlightColor:Colors.grey[800],
                  onPressed: () => controller.rotate(-90),
                ),
              ),
              // 自由旋转暂时没有实现滑块，先做一个占位按钮
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  tooltip: "自由旋转",
                  icon: Icon(Icons.rotate_left_outlined, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: controller.activeTool == EditToolsMenu.rotateFree ? Colors.grey[800] : Colors.transparent,
                  ),
                  onPressed: () {
                    // 自由旋转逻辑需要滑块，这里先切换状态
                    controller.selectTool(EditToolsMenu.rotateFree);
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  tooltip: "顺时针90°",
                  icon: Icon(CupertinoIcons.rotate_right, color: Colors.white),
                  highlightColor:Colors.grey[800],
                  onPressed: () => controller.rotate(90),
                ),
              )
            ],
          ),
          // 暂时子菜单只有三个 不要滚动
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //
          // ),
        ],
      )
    );
  }
}
