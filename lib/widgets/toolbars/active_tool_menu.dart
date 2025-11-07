// image_editor/lib/widgets/toolbars/active_tool_menu.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';
import 'crop_toolbar.dart';
import 'rotate_toolbar.dart';
import 'text_toolbar.dart';

/// 这个Widget根据控制器中当前激活的工具，动态显示对应的子菜单
class ActiveToolMenu extends StatelessWidget {

  final ImageEditorController controller;

  const ActiveToolMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (isCropTool(controller.activeTool)) {
      return commonToolBar(child: CropToolbar(controller: controller) , context: context);
    }
    if (isRotateTool(controller.activeTool)) {
      return commonToolBar(child: RotateToolbar(controller: controller), context: context);
    }
    if (controller.activeTool == EditToolsMenu.text) {
      return commonToolBar(child:TextToolbar(controller: controller) , context: context );
    }
    return const SizedBox.shrink(); // 没有激活的子菜单时返回空SizedBox
  }

  Widget commonToolBar ({
    required Widget child,
    required BuildContext context
  }){
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      color: Colors.black,
      child: Row(
        crossAxisAlignment:CrossAxisAlignment.end,
        children: [
          IconButton(
            highlightColor: Colors.grey[800] ,
            onPressed: controller.isBusy ? null : () => controller.cancelCurrentTool(),
            icon: Icon(Icons.close ,  size: 18,  color: controller.isBusy ? Colors.grey[700] : Colors.grey)
          ),
          Expanded(child: child),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                highlightColor: Colors.grey[800] ,
                onPressed: controller.isBusy
                    ? null
                    : () async => await controller.applyCurrentTool(),
                icon: Icon(Icons.check,  size: 20, color: controller.isBusy ? Colors.orange.withValues(alpha: 0.5) : Colors.orange)
              ),
              if (controller.isBusy)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                ),
            ],
          )
        ],
      ),
    );
  }
}


