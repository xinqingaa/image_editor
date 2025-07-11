// image_editor/lib/image_editor.dart

library image_editor;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'widgets/image_editor_view.dart';

// 导出主编辑器Widget，方便外部直接使用
export 'models/editor_models.dart' show EditToolsMenu;

class ImageEditor extends StatelessWidget {
  final ui.Image image;

  const ImageEditor({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return ImageEditorView(image: image);
  }
}
