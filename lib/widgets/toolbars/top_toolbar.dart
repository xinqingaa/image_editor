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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.black.withOpacity(0.8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 取消按钮（左侧）
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "取消",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[200],
                ),
              ),
            ),
            // 标题"编辑"（中间）
            const Text(
              "编辑",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // 导出按钮（右侧）
            TextButton(
              onPressed: () async {
                final resultImage = await controller.exportImage();
                Navigator.pop(context, resultImage);
              },
              child: const Text(
                "导出",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

