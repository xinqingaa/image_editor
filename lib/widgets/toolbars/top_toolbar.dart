// image_editor/lib/widgets/toolbars/top_toolbar.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';

/// 顶部工具栏
/// 包含：取消（左侧）、标题"编辑"（中间）、导出（右侧）
class TopToolbar extends StatelessWidget {
  final ImageEditorController controller;

  const TopToolbar({super.key, required this.controller});

  Future<void> _onConfirm(BuildContext context) async {
    // 显示加载指示器（可选，但建议）
    // e.g., showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));

    // [核心修复] 如果是单一工具模式，并且有工具处于激活状态，
    // 那么在导出之前，先应用当前工具的修改。
    if (controller.isSingleToolMode && controller.activeTool != EditToolsMenu.none) {
      await controller.applyCurrentTool();
    }

    // 现在 activeTool 已经是 none 了，图片也已经被裁剪，可以安全导出了
    final resultImage = await controller.exportImage();

    // 隐藏加载指示器（如果显示了）
    // if (context.mounted) Navigator.pop(context); 

    // 返回结果
    if (context.mounted) {
      Navigator.pop(context, resultImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolbarConfig = controller.config.topToolbar;
    final backgroundColor = toolbarConfig.backgroundColor ?? Colors.black.withValues(alpha: 0.8);
    final cancelText = toolbarConfig.cancelText ?? "返回";
    final titleText = toolbarConfig.titleText ?? "编辑";
    final confirmText = toolbarConfig.confirmText ?? "完成";
    final cancelColor = toolbarConfig.cancelTextColor ?? Colors.grey.shade200;
    final titleColor = toolbarConfig.titleTextColor ?? Colors.white;
    final confirmColor = toolbarConfig.confirmTextColor ?? Colors.white;

    return SafeArea(
      child: Container(
        color: backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                cancelText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cancelColor,
                ),
              ),
            ),
            Text(
              titleText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            TextButton(
              onPressed: () => _onConfirm(context),
              child: Text(
                confirmText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: confirmColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
