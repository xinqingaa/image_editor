// image_editor/lib/widgets/image_editor_view.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../controller/image_editor_controller.dart';

import 'painter.dart';
import 'toolbars/active_tool_menu.dart';
import 'toolbars/main_toolbar.dart';


/// 图片编辑器主视图 Widget
/// 这是包的入口UI，负责创建和管理Controller的生命周期
class ImageEditorView extends StatefulWidget {
  final ui.Image image;

  const ImageEditorView({super.key, required this.image});

  @override
  State<ImageEditorView> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView> {
  late final ImageEditorController _controller;

  @override
  void initState() {
    super.initState();
    // 创建控制器实例
    _controller = ImageEditorController(image: widget.image);
  }

  @override
  void dispose() {
    _controller.dispose(); // 释放控制器资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用ListenableBuilder可以更高效地监听Controller的变化
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              Expanded(
                child: _buildEditorCanvas(),
              ),
              // 当前激活工具的子菜单 (如裁剪选项)
              ActiveToolMenu(controller: _controller),
              // 主工具栏 (裁剪、旋转、文字等)
              const SizedBox(height: 12,),
              MainToolbar(controller: _controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditorCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 及时将画布尺寸告知 Controller
        _controller.setCanvasSize(constraints.biggest);
        if (_controller.canvasSize == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return GestureDetector(
          onScaleStart: _controller.onScaleStart,
          onScaleUpdate: _controller.onScaleUpdate,
          onScaleEnd: _controller.onScaleEnd,
          child: CustomPaint(
            size: _controller.canvasSize!,
            painter: ImageEditorPainter(controller: _controller,),
          ),
        );
      },
    );
  }
}
