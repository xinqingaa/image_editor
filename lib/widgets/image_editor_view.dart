import 'package:flutter/material.dart';
import '../widgets/toolbars/text_properties_toolbar.dart';
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
  final ImageEditorConfig config;

  const ImageEditorView({
    super.key,
    required this.image,
    this.config = const ImageEditorConfig(),
  });

  @override
  State<ImageEditorView> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView> {
  late final ImageEditorController _controller;

  @override
  void initState() {
    super.initState();
    // 创建控制器实例
    _controller = ImageEditorController(
      image: widget.image,
      config: widget.config,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 释放控制器资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              // 顶部工具栏
              TopToolbar(controller: _controller),
              // 中间画布区域（自动占据剩余空间）
              Expanded(
                child: _buildEditorCanvas(),
              ),
              // 底部工具栏
              _buildBottomToolbars(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditorCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.biggest 现在就是真实可用的画布空间
        // 因为 Expanded 已经自动减去了工具栏的高度
        final canvasSize = constraints.biggest;
        
        // 直接使用真实的可用尺寸
        _controller.setCanvasSize(canvasSize);
        
        if (_controller.canvasSize == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return GestureDetector(
          onTapDown: _controller.onTapDown,
          onScaleStart: _controller.onScaleStart,
          onScaleUpdate: _controller.onScaleUpdate,
          onScaleEnd: _controller.onScaleEnd,
          child: CustomPaint(
            size: canvasSize,
            painter: ImageEditorPainter(controller: _controller),
          ),
        );
      },
    );
  }

  // 用于管理底部工具栏的显示逻辑
  Widget _buildBottomToolbars() {
    // 1. 优先处理文本图层被选中的情况（编辑现有文本）
    if (_controller.selectedTextLayerId != null) {
      return TextPropertiesToolbar(controller: _controller);
    }

    // 2. 如果处于锁定模式
    if (_controller.isSingleToolMode) {
      final lockedTool = _controller.config.lockToTool!;
      // 如果锁定的工具是旋转或文本，则显示 ActiveToolMenu
      if (isRotateTool(_controller.convertLockModeToTool(lockedTool)) || _controller.convertLockModeToTool(lockedTool) == EditToolsMenu.text) {
        return ActiveToolMenu(controller: _controller);
      }
      // 如果锁定的工具是裁剪，则不显示任何底部工具栏
      return const SizedBox.shrink();
    }

    // 3. 正常模式下的逻辑
    // 如果有激活的工具（用户从主工具栏点击进入）
    if (_controller.activeTool != EditToolsMenu.none) {
      return ActiveToolMenu(controller: _controller);
    }
    // 默认显示主工具栏
    return MainToolbar(controller: _controller);
  }
}