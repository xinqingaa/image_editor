// image_editor/lib/widgets/toolbars/top_toolbar.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';

/// 顶部工具栏
/// 包含：取消（左侧）、标题"编辑"（中间）、导出（右侧）
class TopToolbar extends StatelessWidget {
  final ImageEditorController controller;

  const TopToolbar({super.key, required this.controller});

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
              onPressed: () async {
                final resultImage = await controller.exportImage();
                if(context.mounted){
                  Navigator.pop(context, resultImage);
                }
              },
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

