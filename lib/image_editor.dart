library;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'widgets/image_editor_view.dart';
import 'models/editor_models.dart';

// 导出主编辑器Widget，方便外部直接使用
export 'models/editor_models.dart'
    show EditToolsMenu, ImageEditorConfig, CropOptionConfig, RotateOptionConfig, TopToolbarConfig;
export 'utils/image_loader.dart';

class ImageEditor extends StatelessWidget {
  final ui.Image image;
  final ImageEditorConfig config;

  const ImageEditor({
    super.key,
    required this.image,
    this.config = const ImageEditorConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return ImageEditorView(image: image, config: config);
  }
}
