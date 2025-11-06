// image_editor/lib/widgets/image_editor_view.dart

import 'package:flutter/material.dart';
import 'package:image_editor/widgets/toolbars/text_properties_toolbar.dart';
import 'dart:ui' as ui;

import '../controller/image_editor_controller.dart';

import '../models/editor_models.dart';
import 'painter.dart';
import 'toolbars/active_tool_menu.dart';
import 'toolbars/main_toolbar.dart';
import 'toolbars/top_toolbar.dart';


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
          body: Stack(
            children: [
              // 画布将始终占据整个 Stack
              Positioned.fill(
                child: _buildEditorCanvas(),
              ),
              // 顶部工具栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TopToolbar(controller: _controller),
              ),
              // 底部工具栏将作为浮层，定位在底部
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomToolbars(),
              ),
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
          onTapDown: _controller.onTapDown, // 处理文字图层
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

  // [新增] 用于管理底部工具栏的显示逻辑
  Widget _buildBottomToolbars() {
    // 优先显示文本属性工具栏
    if (_controller.selectedTextLayerId != null) {
      return TextPropertiesToolbar(controller: _controller);
    }
    // 其次显示激活的工具菜单 (裁剪、旋转等)
    if (_controller.activeTool != EditToolsMenu.none) {
      return ActiveToolMenu(controller: _controller);
    }
    // 最后显示主工具栏
    return MainToolbar(controller: _controller);
  }
}
