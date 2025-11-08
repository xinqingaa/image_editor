import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editor_models.dart';
import 'history_manager.dart';
import 'text_layer_manager.dart';
import 'crop_handler.dart';
import 'rotation_handler.dart';


/// 图片编辑器控制器
/// 继承自 ChangeNotifier，用于管理所有编辑状态和业务逻辑。
/// UI层通过监听此控制器来响应状态变化。
class ImageEditorController extends ChangeNotifier {
  // ----------------- 核心状态 -----------------
  ui.Image _image;
  ui.Image get image => _image;

  EditToolsMenu _activeTool = EditToolsMenu.none;
  EditToolsMenu get activeTool => _activeTool;

  final ImageEditorConfig config;

  Size? _canvasSize;
  Size? get canvasSize => _canvasSize;

  double _currentRotationAngle = 0.0;
  double get currentRotationAngle => _currentRotationAngle;

  double _scale = 1.0;
  double get scale => _scale;

  double _translateX = 0.0;
  double get translateX => _translateX;

  double _translateY = 0.0;
  double get translateY => _translateY;

  Rect? _cropRect;
  Rect? get cropRect => _cropRect;

  bool get isCroppingActive => isCropTool(_activeTool);

  // -----------------文本图层相关状态----------------------
  // 获取文本图层列表（委托给 TextLayerManager，保持向后兼容）
  List<TextLayerData> get textLayers => _textLayerManager.layers;
  // 用于临时存储当前正在输入的文本
  String _editingText = '';
  // [新增] 核心状态：当前选中的文本图层ID（委托给 TextLayerManager）
  String? get selectedTextLayerId => _textLayerManager.selectedLayerId;
  // [新增] 拖动相关的临时状态
  Offset? _dragTextStartPoint;
  Offset? _initialLayerOffset;


  // ----------------- 手势和拖拽相关的临时状态 -----------------
  double _previousScale = 1.0;
  DragHandlePosition? _activeDragHandle;
  DragHandlePosition? get activeDragHandle => _activeDragHandle;
  Offset? _dragStartPoint;
  Offset? _initialCropRectOffsetForDrag;

  // ----------------- 配置项 -----------------
  final double handleVisualSize = 8.0;
  final double _handleTouchSize = 24.0;
  final double _minCropSize = 50.0;


  // --- [临时状态，用于取消操作] ---
  Rect? _backupCropRect;
  double _backupRotationAngle = 0.0;

  // --- [历史状态管理] ---
  /// 原始图片（最初加载的图片）
  final ui.Image _originalImage;
  

  // --- [组合模式：Handler 和 Manager 实例] ---
  /// 历史记录管理器
  final HistoryManager _historyManager = HistoryManager();
  
  /// 文本图层管理器
  final TextLayerManager _textLayerManager = TextLayerManager();

  /// 构造函数，需要传入一个初始图片
  ImageEditorController({
    required ui.Image image,
    this.config = const ImageEditorConfig(),
  })  : _image = image,
        _originalImage = image;

  bool get isCropFeatureEnabled =>
      config.enableCrop && config.hasEnabledCropOption;

  bool get isRotateFeatureEnabled => config.enableRotate;

  bool get isTextFeatureEnabled => config.enableText;

  // 是否正在执行操作
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  // 设置是否正在执行操作
  void _setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    notifyListeners();
  }

  // 判断工具是否启用
  bool isToolEnabled(EditToolsMenu tool) {
    if (tool == EditToolsMenu.none) {
      return true;
    }
    if (isCropTool(tool)) {
      if (!isCropFeatureEnabled) return false;
      switch (tool) {
        case EditToolsMenu.cropFree:
          return config.cropOptions.enableFree;
        case EditToolsMenu.crop16_9:
          return config.cropOptions.enable16By9;
        case EditToolsMenu.crop5_4:
          return config.cropOptions.enable5By4;
        case EditToolsMenu.crop1_1:
          return config.cropOptions.enable1By1;
        default:
          return false;
      }
    }
    if (isRotateTool(tool)) {
      return isRotateFeatureEnabled;
    }
    if (tool == EditToolsMenu.text) {
      return isTextFeatureEnabled;
    }
    return false;
  }

  EditToolsMenu? _resolveCropTool(EditToolsMenu tool) {
    if (!isCropTool(tool)) return tool;
    if (!isToolEnabled(tool)) {
      // 选择第一个可用的裁剪选项
      final candidates = <EditToolsMenu>[
        EditToolsMenu.cropFree,
        EditToolsMenu.crop16_9,
        EditToolsMenu.crop5_4,
        EditToolsMenu.crop1_1,
      ];
      try {
        return candidates.firstWhere(isToolEnabled);
      } catch (_) {
        return null;
      }
    }
    return tool;
  }

  /// UI层在布局完成后需要调用此方法设置画布尺寸
  void setCanvasSize(Size size) {
    // 检查是否是第一次设置。用 _canvasSize == null 更可靠。
    if (_canvasSize == null) {
      _canvasSize = size;
      // 使用 addPostFrameCallback 将初始化操作延迟到 build 周期之后
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 确保控制器没有被 dispose
        if (_canvasSize != null) {
          _initializeImageScale();
        }
      });
    }
    // 如果画布尺寸发生变化（例如屏幕旋转），也需要处理
    else if (_canvasSize != size) {
      _canvasSize = size;
      // 这里可以添加逻辑来重新计算缩放等，如果需要的话
    }
  }

  void _initializeImageScale() {
    if (_canvasSize == null) return;
    // 1. 直接使用画布的完整尺寸，让图片占满100%
    final double targetWidth = _canvasSize!.width;
    final double targetHeight = _canvasSize!.height;
    // 2. 基于目标尺寸计算宽度和高度的缩放比
    final double widthRatio = targetWidth / _image.width;
    final double heightRatio = targetHeight / _image.height;
    // 3. 取两个比例中较小的一个，以确保图片完整显示在目标区域内，并保持其原始宽高比
    // 这样限制方向会占满100%
    _scale = math.min(widthRatio, heightRatio);
    // 4. 通知UI更新
    notifyListeners();
  }

  /// 重置所有变换状态，通常在替换图片或完成裁剪后调用
  void resetTransformations({ui.Image? newImage}) {
    if (newImage != null) {
      _image = newImage;
    }
    _currentRotationAngle = 0.0;
    _translateX = 0.0;
    _translateY = 0.0;
    _scale = 1.0; // 重置为1.0，让_initializeImageScale重新计算
    _initializeImageScale();
    notifyListeners();
  }

  // --- [历史状态管理方法] ---

  /// 保存当前状态到历史快照
  void _saveStateSnapshot() {
    _historyManager.saveSnapshot(
      image: _image,
      textLayers: _textLayerManager.copyLayers(),
      rotationAngle: _currentRotationAngle,
      scale: 0.0, // scale 会在回退时根据恢复的图片尺寸重新计算，这里保存0作为占位符
    );
  }

  /// 检查是否可以回退（是否有历史记录）
  bool get canUndo => _historyManager.canUndo;

  /// 检查是否可以完全撤销（是否与原始状态不同）
  bool get canResetToOriginal {
    // 检查图片是否不同
    if (_image != _originalImage) {
      return true;
    }
    // 检查是否有文本图层
    if (!_textLayerManager.isEmpty) {
      return true;
    }
    // 检查是否有旋转
    if (_currentRotationAngle != 0.0) {
      return true;
    }
    // 检查缩放是否不是初始值（虽然初始值会在_initializeImageScale中计算，但这里检查是否为1.0）
    // 实际上，scale会在_initializeImageScale中重新计算，所以这里主要检查其他状态
    return false;
  }

  /// 完全撤销：重置到原始图片和初始状态
  void resetToOriginal() {
    _image = _originalImage;
    _currentRotationAngle = 0.0;
    _translateX = 0.0;
    _translateY = 0.0;
    _scale = 1.0;
    _textLayerManager.clear();
    _cropRect = null;
    _backupCropRect = null;
    _activeTool = EditToolsMenu.none;
    
    // 清空历史记录
    _historyManager.clear();
    
    // 重新初始化缩放
    if (_canvasSize != null) {
      _initializeImageScale();
    }
    notifyListeners();
  }

  /// 回退：撤销最后一次应用的操作
  void undoLastOperation() {
    final snapshot = _historyManager.popSnapshot();
    if (snapshot == null) {
      return;
    }

    // 恢复状态
    _image = snapshot.image;
    _currentRotationAngle = snapshot.rotationAngle;
    // 注意：不直接恢复 _scale，因为它是根据图片尺寸和画布尺寸动态计算的
    // 恢复图片后需要重新计算 _scale
    
    // 恢复文本图层（委托给 TextLayerManager）
    _textLayerManager.restoreLayers(snapshot.textLayers);
    
    // 清除选择状态
    _cropRect = null;
    _backupCropRect = null;
    _activeTool = EditToolsMenu.none;

    // 恢复图片后，重新计算缩放以适应画布
    // 这是必要的，因为图片尺寸可能已经改变了（裁剪或旋转后）
    if (_canvasSize != null) {
      _initializeImageScale();
    }
    notifyListeners();
  }


  // 一个公共方法，让 TextToolbar 可以更新正在编辑的文本
  void updateEditingText(String text) {
    _editingText = text;
  }



  // ----------------- 工具应用与取消逻辑 -----------------

  /// 应用当前工具的修改
  Future<void> applyCurrentTool() async {
    if (_isBusy) return;
    _setBusy(true);
    // 在应用操作前保存当前状态到历史快照
    // 注意：对于旋转操作，应用后图片会旋转，角度会重置为0
    // 所以保存快照时，应该保存应用前的图片和角度为0（因为应用后角度会重置为0）
    if (isRotateTool(_activeTool)) {
      // 对于旋转操作，保存旋转前的状态
      // 应用旋转后，图片会旋转，角度会重置为0，所以保存角度为0
      _historyManager.saveSnapshot(
        image: _image,
        textLayers: _textLayerManager.copyLayers(),
        rotationAngle: 0.0, // 应用旋转后角度会重置为0，所以保存0
        scale: 0.0, // scale 会在回退时重新计算，这里保存0作为占位符
      );
    } else {
      // 对于其他操作（裁剪、文本），正常保存当前状态
      _saveStateSnapshot();
    }
    
    try {
      if (isCropTool(_activeTool)) {
        await _applyCrop();
      } else if (isRotateTool(_activeTool)) {
        await _applyRotation();
      } else if (_activeTool == EditToolsMenu.text) {
        // [新增] 处理添加文本的逻辑
        _applyText();
      }
      // 关闭工具菜单
      _activeTool = EditToolsMenu.none;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  /// 取消当前工具的修改
  void cancelCurrentTool() {
    if (_isBusy) return;
    if (isCropTool(_activeTool)) {
      // 恢复裁剪框到进入工具前的状态
      _cropRect = _backupCropRect;
    } else if (isRotateTool(_activeTool)) {
      // 恢复旋转角度
      _currentRotationAngle = _backupRotationAngle;
    }
    // 关闭工具菜单
    _activeTool = EditToolsMenu.none;
    _backupCropRect = null;
    notifyListeners();
  }


  // ----------------- 公共方法：由UI层调用 -----------------

  /// 切换主工具
  void selectTool(EditToolsMenu tool) {
    EditToolsMenu? resolvedTool;
    if (isCropTool(tool)) {
      resolvedTool = _resolveCropTool(tool);
    } else if (isRotateTool(tool) || tool == EditToolsMenu.text) {
      resolvedTool = isToolEnabled(tool) ? tool : null;
    } else {
      resolvedTool = tool;
    }

    if (resolvedTool == null) {
      return; // 所请求的工具被禁用
    }

    if (_activeTool == resolvedTool) {
      // 如果重复点击同一个工具，则关闭它
      cancelCurrentTool();
      return;
    }
    _activeTool = resolvedTool;
    // 进入工具时，备份当前状态以便取消
    if (isCroppingActive) {
      _backupCropRect = _cropRect; // 备份当前裁剪框
      _initializeCropRect(aspectRatio: _getCurrentAspectRatio());
    } else {
      _cropRect = null; // 确保非裁剪模式下没有裁剪框
    }
    if (isRotateTool(_activeTool)) {
      _backupRotationAngle = _currentRotationAngle; // 备份当前旋转角度
    }
    notifyListeners();
  }

  /// 选择特定的裁剪工具（带宽高比）
  void selectCropTool(EditToolsMenu tool, {double? aspectRatio}) {
    final resolvedTool = _resolveCropTool(tool);
    if (resolvedTool == null) {
      return;
    }
    _activeTool = resolvedTool;
    final targetAspectRatio = aspectRatio ?? _getAspectRatioForTool(resolvedTool);
    _initializeCropRect(aspectRatio: targetAspectRatio);
    notifyListeners();
  }


  /// 旋转图片（按指定角度）
  void rotate(double degrees) {
    _currentRotationAngle += (degrees * math.pi / 180.0);
    notifyListeners();
  }

  /// @param degrees - 从滑块传来的角度值 (-45 to +45)
  void updateFreeRotation(double degrees) {
    // 核心逻辑：在进入旋转工具时备份的初始角度上，增加滑块提供的增量
    _currentRotationAngle = _backupRotationAngle + (degrees * math.pi / 180.0);
    notifyListeners();
  }

  /// 完成操作，导出最终图片
  // Future<ui.Image?> exportImage() async {
  //   if (isCroppingActive && _cropRect != null) {
  //     return await _captureCroppedImage();
  //   }
  //   // 如果不是裁剪模式，可以根据需要实现导出应用了旋转和缩放的图片
  //   // 这里为简化，直接返回当前图片（未应用变换）
  //   // 若要导出带变换的图片，需要一个类似_captureCroppedImage的渲染过程
  //   return _image;
  // }

  Future<ui.Image?> exportImage() async {
    if (_canvasSize == null) return null;
    // 导出时，我们渲染当前所见即所得的视图
    return await _captureTransformedImage();
  }

  // ----------------- 手势处理逻辑 -----------------

  void onScaleStart(ScaleStartDetails details) {
    // 优先处理文本拖动
    final selectedId = _textLayerManager.selectLayerAt(
      details.localFocalPoint,
      _canvasSize ?? Size.zero,
    );
    if (selectedId != null) {
      _dragTextStartPoint = details.localFocalPoint;
      final selectedLayer = _textLayerManager.selectedLayer;
      if (selectedLayer != null) {
        _initialLayerOffset = selectedLayer.position;
      }
      notifyListeners();
      return; // 命中文字，中断后续操作
    }


    if (isCroppingActive) {
      _onCropDragStart(details.localFocalPoint);
    } else {
      _previousScale = _scale;
    }
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    // 如果有选中的文字，则执行拖动逻辑
    if (_textLayerManager.hasSelection && _dragTextStartPoint != null && _initialLayerOffset != null) {
      final dragDelta = details.localFocalPoint - _dragTextStartPoint!;
      _textLayerManager.updateSelectedLayerPosition(_initialLayerOffset! + dragDelta);
      notifyListeners();
      return;
    }
    // 如果没有文字 执行裁剪框逻辑
    if (isCroppingActive && _activeDragHandle != null) {
      _onCropDragUpdate(details.localFocalPoint);
    } else if (!isCroppingActive) {
      _scale = (_previousScale * details.scale).clamp(0.2, 5.0);
      // 注意：平移逻辑需要根据具体交互设计调整，这里暂时注释掉
      // _translateX += details.focalPointDelta.dx;
      // _translateY += details.focalPointDelta.dy;
    }
    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    // 清理文本拖动状态
    if (_textLayerManager.hasSelection) {
      _dragTextStartPoint = null;
      _initialLayerOffset = null;
    }

    if (isCroppingActive) {
      _onCropDragEnd();
    }
  }


  // [新增] 单击事件处理，用于选择/取消选择
  void onTapDown(TapDownDetails details) {
    // 如果没有点中任何文字，则取消选择
    final selectedId = _textLayerManager.selectLayerAt(
      details.localPosition,
      _canvasSize ?? Size.zero,
    );
    if (selectedId == null) {
      _textLayerManager.clearSelection();
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  // [新增] 文本图层操作方法（委托给 TextLayerManager）

  /// 根据点击位置选择文本图层，返回是否命中
  bool selectTextLayerAt(Offset tapPosition) {
    final selectedId = _textLayerManager.selectLayerAt(
      tapPosition,
      _canvasSize ?? Size.zero,
    );
    if (selectedId != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 清除文本选择
  void clearTextSelection() {
    _textLayerManager.clearSelection();
    notifyListeners();
  }

  /// 更新选中图层的颜色
  void updateSelectedTextColor(Color color) {
    if (_textLayerManager.updateSelectedLayerColor(color)) {
      notifyListeners();
    }
  }

  /// 更新选中图层的大小
  void updateSelectedTextSize(double size) {
    if (_textLayerManager.updateSelectedLayerSize(size)) {
      notifyListeners();
    }
  }

  /// 删除选中的文本图层
  void deleteSelectedTextLayer() {
    if (_textLayerManager.removeSelectedLayer()) {
      notifyListeners();
    }
  }


  // ----------------- 私有方法：内部逻辑实现 -----------------

  // 应用文本的私有方法
  void _applyText() {
    // 如果输入为空，则不添加
    if (_editingText.trim().isEmpty) {
      return;
    }
    // 使用 TextLayerManager 添加新图层
    _textLayerManager.addLayer(
      text: _editingText,
      position: canvasSize != null 
          ? Offset(canvasSize!.width / 2, canvasSize!.height / 2) 
          : Offset.zero,
      color: Colors.blue,
      fontSize: 32.0,
    );
    _editingText = ''; // 清空临时文本
  }



  /// [替换旧的_captureCroppedImage]
  /// 一个全新的、高保真的裁剪实现
  Future<ui.Image?> _captureHiResCroppedImage() async {
    if (_cropRect == null || _canvasSize == null) return null;

    // 1. 计算从“图片坐标系”到“屏幕坐标系”的变换矩阵
    final Matrix4 matrixToScreen = Matrix4.identity();
    matrixToScreen
        .multiply(Matrix4.translationValues(_canvasSize!.width / 2, _canvasSize!.height / 2, 0));
    matrixToScreen.rotateZ(_currentRotationAngle);
    matrixToScreen.multiply(Matrix4.diagonal3Values(_scale, _scale, 1));
    matrixToScreen
        .multiply(Matrix4.translationValues(-_image.width / 2, -_image.height / 2, 0));

    // 2. 求逆矩阵，得到从“屏幕坐标系”返回“图片坐标系”的变换
    final Matrix4 screenToImageMatrix = Matrix4.inverted(matrixToScreen);

    // 3. 将屏幕上的裁剪框的四个角，通过逆矩阵变换回图片上的坐标
    final topLeft = MatrixUtils.transformPoint(screenToImageMatrix, _cropRect!.topLeft);
    final topRight = MatrixUtils.transformPoint(screenToImageMatrix, _cropRect!.topRight);
    final bottomLeft = MatrixUtils.transformPoint(screenToImageMatrix, _cropRect!.bottomLeft);
    final bottomRight = MatrixUtils.transformPoint(screenToImageMatrix, _cropRect!.bottomRight);

    // 4. 计算能完全包围这四个点的、在图片坐标系中的矩形边界 (sourceRect)
    final double minX = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx].reduce(math.min);
    final double maxX = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx].reduce(math.max);
    final double minY = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy].reduce(math.min);
    final double maxY = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy].reduce(math.max);

    final Rect sourceRect = Rect.fromLTRB(minX, minY, maxX, maxY);

    // 5. 计算新图片的尺寸（高保真尺寸）
    final int newWidth = sourceRect.width.round();
    final int newHeight = sourceRect.height.round();

    if (newWidth <= 0 || newHeight <= 0) return null;

    // 6. 使用 PictureRecorder 和 drawImageRect 进行高保真绘制
    final recorder = ui.PictureRecorder();
    // 创建一个尺寸为高保真尺寸的画布
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()));

    final paint = Paint()..filterQuality = FilterQuality.high;

    // 定义目标矩形为整个新画布
    final Rect destinationRect = Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble());

    // 核心：从原图(_image)的 sourceRect 区域，绘制到新画布的 destinationRect 区域
    canvas.drawImageRect(_image, sourceRect, destinationRect, paint);

    // 7. 生成最终的高清图片
    final picture = recorder.endRecording();
    return await picture.toImage(newWidth, newHeight);
  }

  Future<void> _applyCrop() async {
    if (_cropRect == null) return;
    // 调用新的、高保真的裁剪方法
    final croppedImage = await _captureHiResCroppedImage();
    if (croppedImage != null) {
      resetTransformations(newImage: croppedImage);
    }
    _cropRect = null;
    _backupCropRect = null;
  }

  ///  应用旋转（委托给 RotationHandler）
  Future<void> _applyRotation() async {
    if (_currentRotationAngle == _backupRotationAngle) {
      // 如果角度没有变化，则无需操作
      return;
    }
    // 使用 RotationHandler 渲染旋转后的图片
    final rotatedImage = await RotationHandler.renderRotatedImage(
      image: _image,
      angle: _currentRotationAngle,
    );
    // 用旋转后的图片替换，并重置所有变换
    resetTransformations(newImage: rotatedImage);
  }



  /// [新增] 捕获当前所有变换（旋转、缩放、平移）后的最终图像
  /// 使用原图像素尺寸保持高清晰度
  Future<ui.Image> _captureTransformedImage() async {
    // 1. 计算旋转后图片的边界框尺寸（使用原图像素尺寸）
    final angle = _currentRotationAngle;
    final sinAngle = math.sin(angle).abs();
    final cosAngle = math.cos(angle).abs();
    final rotatedWidth = _image.width * cosAngle + _image.height * sinAngle;
    final rotatedHeight = _image.width * sinAngle + _image.height * cosAngle;

    // 2. 计算屏幕到像素的缩放比例
    // 屏幕上的图片尺寸 = 原图尺寸 * scale
    // 所以像素坐标 = 屏幕坐标 / scale
    final double pixelScale = 1.0 / _scale;

    // 3. 计算导出画布的尺寸（使用原图像素尺寸）
    final int exportWidth = rotatedWidth.round();
    final int exportHeight = rotatedHeight.round();

    // 4. 创建高分辨率画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, exportWidth.toDouble(), exportHeight.toDouble()));

    // 5. 绘制变换后的图片（使用高保真绘制）
    final paint = Paint()..filterQuality = FilterQuality.high;
    final canvasCenterX = exportWidth / 2;
    final canvasCenterY = exportHeight / 2;
    canvas.save();
    canvas.translate(canvasCenterX, canvasCenterY);
    canvas.rotate(angle);
    // 注意：这里不应用scale，因为我们已经在像素坐标系中
    canvas.drawImage(_image, Offset(-_image.width / 2, -_image.height / 2), paint);
    canvas.restore();

    // 6. 绘制所有文本图层（需要将屏幕坐标转换为像素坐标）
    // 计算从图片坐标系到屏幕坐标系的变换矩阵（与 _captureHiResCroppedImage 中的逻辑一致）
    final Matrix4 imageToScreenMatrix = Matrix4.identity();
    imageToScreenMatrix
        .multiply(Matrix4.translationValues(_canvasSize!.width / 2, _canvasSize!.height / 2, 0));
    imageToScreenMatrix.rotateZ(_currentRotationAngle);
    imageToScreenMatrix.multiply(Matrix4.diagonal3Values(_scale, _scale, 1));
    imageToScreenMatrix
        .multiply(Matrix4.translationValues(-_image.width / 2, -_image.height / 2, 0));
    // 求逆矩阵，得到从屏幕坐标系到图片坐标系的变换
    final Matrix4 screenToImageMatrix = Matrix4.inverted(imageToScreenMatrix);
    
    // 计算从图片坐标系到导出画布坐标系的变换矩阵
    final Matrix4 imageToExportMatrix = Matrix4.identity();
    imageToExportMatrix
        .multiply(Matrix4.translationValues(exportWidth / 2, exportHeight / 2, 0));
    imageToExportMatrix.rotateZ(angle);
    imageToExportMatrix
        .multiply(Matrix4.translationValues(-_image.width / 2, -_image.height / 2, 0));
    
    for (final layer in textLayers) {
      // 创建段落样式
      final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.center);
      // 创建文本样式（字体大小也需要按比例缩放）
      final textStyle = ui.TextStyle(
        color: layer.color,
        fontSize: layer.fontSize * pixelScale,
      );
      // 构建段落
      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(layer.text);
      final paragraph = paragraphBuilder.build();
      // 布局段落（使用像素尺寸）
      paragraph.layout(ui.ParagraphConstraints(width: exportWidth.toDouble()));
      
      // 将屏幕坐标转换为图片坐标，再转换为导出画布坐标
      final imagePos = MatrixUtils.transformPoint(screenToImageMatrix, layer.position);
      final exportPos = MatrixUtils.transformPoint(imageToExportMatrix, imagePos);
      
      // 计算绘制位置
      final Offset textDrawPosition = Offset(
        exportPos.dx - paragraph.width / 2,
        exportPos.dy - paragraph.height / 2,
      );
      // 将文本绘制到导出用的 Canvas 上
      canvas.drawParagraph(paragraph, textDrawPosition);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(exportWidth, exportHeight);
  }

  /// 计算旋转后图片在屏幕上的实际显示边界框
  /// 返回一个 Rect，表示图片在屏幕坐标系中的实际显示区域
  Rect _getImageDisplayBounds() {
    if (_canvasSize == null) {
      return Rect.zero;
    }

    // 1. 图片的四个角在图片坐标系中的坐标
    final double halfWidth = _image.width / 2;
    final double halfHeight = _image.height / 2;
    final List<Offset> imageCorners = [
      Offset(-halfWidth, -halfHeight), // 左上
      Offset(halfWidth, -halfHeight),  // 右上
      Offset(-halfWidth, halfHeight),  // 左下
      Offset(halfWidth, halfHeight),   // 右下
    ];

    // 2. 构建从图片坐标系到屏幕坐标系的变换矩阵
    final Matrix4 imageToScreenMatrix = Matrix4.identity();
    imageToScreenMatrix
        .multiply(Matrix4.translationValues(_canvasSize!.width / 2, _canvasSize!.height / 2, 0));
    imageToScreenMatrix.rotateZ(_currentRotationAngle);
    imageToScreenMatrix.multiply(Matrix4.diagonal3Values(_scale, _scale, 1));

    // 3. 将图片的四个角变换到屏幕坐标系
    final List<Offset> screenCorners = imageCorners.map((corner) {
      return MatrixUtils.transformPoint(imageToScreenMatrix, corner);
    }).toList();

    // 4. 计算边界框
    final double minX = screenCorners.map((p) => p.dx).reduce(math.min);
    final double maxX = screenCorners.map((p) => p.dx).reduce(math.max);
    final double minY = screenCorners.map((p) => p.dy).reduce(math.min);
    final double maxY = screenCorners.map((p) => p.dy).reduce(math.max);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _initializeCropRect({double? aspectRatio}) {
    if (_canvasSize == null) return;

    // 获取图片的实际显示边界
    final Rect imageBounds = _getImageDisplayBounds();

    // 使用 CropHandler 初始化裁剪框
    _cropRect = CropHandler.initializeCropRect(
      canvasSize: _canvasSize!,
      imageBounds: imageBounds,
      aspectRatio: aspectRatio,
    );
  }

  void _onCropDragStart(Offset localPosition) {
    if (_cropRect == null) return;
    _dragStartPoint = localPosition;
    _activeDragHandle = _getDragHandleForPosition(localPosition, _cropRect!, _handleTouchSize);
    if (_activeDragHandle == DragHandlePosition.inside) {
      _initialCropRectOffsetForDrag = _cropRect!.topLeft - localPosition;
    } else {
      _initialCropRectOffsetForDrag = null;
    }
    notifyListeners();
  }

  void _onCropDragUpdate(Offset localPosition) {
    if (_cropRect == null || _activeDragHandle == null || _dragStartPoint == null) return;

    final Offset delta = localPosition - _dragStartPoint!;
    _dragStartPoint = localPosition;

    Rect newRect = _cropRect!;
    final double? aspectRatio = _getCurrentAspectRatio();

    switch (_activeDragHandle!) {
      case DragHandlePosition.inside:
        if (_initialCropRectOffsetForDrag != null) {
          newRect = Rect.fromLTWH((localPosition + _initialCropRectOffsetForDrag!).dx,
              (localPosition + _initialCropRectOffsetForDrag!).dy, newRect.width, newRect.height);
        }
        break;
      case DragHandlePosition.topLeft:
        {
          final double fixedRight = newRect.right;
          final double fixedBottom = newRect.bottom;
          double newLeft = newRect.left + delta.dx;
          double newTop = newRect.top + delta.dy;
          double tentativeWidth = fixedRight - newLeft;
          double tentativeHeight = fixedBottom - newTop;
          if (aspectRatio != null) {
            if (tentativeWidth / (tentativeHeight != 0 ? tentativeHeight : 1e-6) > aspectRatio) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newTop = fixedBottom - tentativeHeight;
            } else {
              tentativeWidth = tentativeHeight * aspectRatio;
              newLeft = fixedRight - tentativeWidth;
            }
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            newLeft = fixedRight - tentativeWidth;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newTop = fixedBottom - tentativeHeight;
            }
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            newTop = fixedBottom - tentativeHeight;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newLeft = fixedRight - tentativeWidth;
            }
          }
          newRect = Rect.fromLTWH(newLeft, newTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.topMiddle:
        {
          final double fixedBottom = newRect.bottom;
          final double horizontalCenter = newRect.center.dx;
          double newTop = newRect.top + delta.dy;
          double tentativeHeight = fixedBottom - newTop;
          double tentativeWidth = newRect.width;
          if (aspectRatio != null) {
            tentativeWidth = tentativeHeight * aspectRatio;
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            newTop = fixedBottom - tentativeHeight;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
            }
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newTop = fixedBottom - tentativeHeight;
            }
          }
          double newLeft = horizontalCenter - tentativeWidth / 2;
          newRect = Rect.fromLTWH(newLeft, newTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.topRight:
        {
          final double fixedLeft = newRect.left;
          final double fixedBottom = newRect.bottom;
          double newRight = newRect.right + delta.dx;
          double newTop = newRect.top + delta.dy;
          double tentativeWidth = newRight - fixedLeft;
          double tentativeHeight = fixedBottom - newTop;
          if (aspectRatio != null) {
            if (tentativeWidth / (tentativeHeight != 0 ? tentativeHeight : 1e-6) > aspectRatio) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newRight = fixedLeft + tentativeWidth;
            } else {
              tentativeHeight = tentativeWidth / aspectRatio;
              newTop = fixedBottom - tentativeHeight;
            }
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            newRight = fixedLeft + tentativeWidth;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newTop = fixedBottom - tentativeHeight;
            }
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            newTop = fixedBottom - tentativeHeight;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newRight = fixedLeft + tentativeWidth;
            }
          }
          newRect = Rect.fromLTWH(fixedLeft, newTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.middleLeft:
        {
          final double fixedRight = newRect.right;
          final double verticalCenter = newRect.center.dy;
          double newLeft = newRect.left + delta.dx;
          double tentativeWidth = fixedRight - newLeft;
          double tentativeHeight = newRect.height;
          if (aspectRatio != null) {
            tentativeHeight = tentativeWidth / aspectRatio;
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            newLeft = fixedRight - tentativeWidth;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
            }
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newLeft = fixedRight - tentativeWidth;
            }
          }
          double newTop = verticalCenter - tentativeHeight / 2;
          newRect = Rect.fromLTWH(newLeft, newTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.middleRight:
        {
          final double fixedLeft = newRect.left;
          final double verticalCenter = newRect.center.dy;
          double newRight = newRect.right + delta.dx;
          double tentativeWidth = newRight - fixedLeft;
          double tentativeHeight = newRect.height;
          if (aspectRatio != null) {
            tentativeHeight = tentativeWidth / aspectRatio;
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            newRight = fixedLeft + tentativeWidth;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
            }
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newRight = fixedLeft + tentativeWidth;
            }
          }
          double newTop = verticalCenter - tentativeHeight / 2;
          newRect = Rect.fromLTWH(fixedLeft, newTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.bottomLeft:
        {
          final double fixedRight = newRect.right;
          final double fixedTop = newRect.top;
          double newLeft = newRect.left + delta.dx;
          double newBottom = newRect.bottom + delta.dy;
          double tentativeWidth = fixedRight - newLeft;
          double tentativeHeight = newBottom - fixedTop;
          if (aspectRatio != null) {
            if (tentativeWidth / (tentativeHeight != 0 ? tentativeHeight : 1e-6) > aspectRatio) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newLeft = fixedRight - tentativeWidth;
            } else {
              tentativeHeight = tentativeWidth / aspectRatio;
              newBottom = fixedTop + tentativeHeight;
            }
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            newLeft = fixedRight - tentativeWidth;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newBottom = fixedTop + tentativeHeight;
            }
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            newBottom = fixedTop + tentativeHeight;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newLeft = fixedRight - tentativeWidth;
            }
          }
          newRect = Rect.fromLTWH(newLeft, fixedTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.bottomMiddle:
        {
          final double fixedTop = newRect.top;
          final double horizontalCenter = newRect.center.dx;
          double newBottom = newRect.bottom + delta.dy;
          double tentativeHeight = newBottom - fixedTop;
          double tentativeWidth = newRect.width;
          if (aspectRatio != null) {
            tentativeWidth = tentativeHeight * aspectRatio;
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            newBottom = fixedTop + tentativeHeight;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
            }
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newBottom = fixedTop + tentativeHeight;
            }
          }
          double newLeft = horizontalCenter - tentativeWidth / 2;
          newRect = Rect.fromLTWH(newLeft, fixedTop, tentativeWidth, tentativeHeight);
          break;
        }
      case DragHandlePosition.bottomRight:
        {
          final double fixedLeft = newRect.left;
          final double fixedTop = newRect.top;
          double newRight = newRect.right + delta.dx;
          double newBottom = newRect.bottom + delta.dy;
          double tentativeWidth = newRight - fixedLeft;
          double tentativeHeight = newBottom - fixedTop;
          if (aspectRatio != null) {
            if (tentativeWidth / (tentativeHeight != 0 ? tentativeHeight : 1e-6) > aspectRatio) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newRight = fixedLeft + tentativeWidth;
            } else {
              tentativeHeight = tentativeWidth / aspectRatio;
              newBottom = fixedTop + tentativeHeight;
            }
          }
          if (tentativeWidth < _minCropSize) {
            tentativeWidth = _minCropSize;
            newRight = fixedLeft + tentativeWidth;
            if (aspectRatio != null) {
              tentativeHeight = tentativeWidth / aspectRatio;
              newBottom = fixedTop + tentativeHeight;
            }
          }
          if (tentativeHeight < _minCropSize) {
            tentativeHeight = _minCropSize;
            newBottom = fixedTop + tentativeHeight;
            if (aspectRatio != null) {
              tentativeWidth = tentativeHeight * aspectRatio;
              newRight = fixedLeft + tentativeWidth;
            }
          }
          newRect = Rect.fromLTWH(fixedLeft, fixedTop, tentativeWidth, tentativeHeight);
          break;
        }
      }

    // 使用图片的实际显示边界来限制裁剪框
    final Rect imageBounds = _getImageDisplayBounds();
    _cropRect = CropHandler.clampRectToImageBounds(
      rect: newRect,
      imageBounds: imageBounds,
      rotationAngle: _currentRotationAngle,
      canvasSize: _canvasSize!,
      scale: _scale,
      image: _image,
    );
  }

  void _onCropDragEnd() {
    _activeDragHandle = null;
    _dragStartPoint = null;
    _initialCropRectOffsetForDrag = null;
    notifyListeners();
  }



  double? _getCurrentAspectRatio() {
    return CropHandler.getAspectRatio(_activeTool);
  }

  double? _getAspectRatioForTool(EditToolsMenu tool) {
    return CropHandler.getAspectRatio(tool);
  }

  DragHandlePosition? _getDragHandleForPosition(Offset position, Rect cropRect, double handleTouchRadius) {
    if (Rect.fromCircle(center: cropRect.topLeft, radius: handleTouchRadius).contains(position)) return DragHandlePosition.topLeft;
    if (Rect.fromCircle(center: cropRect.topCenter, radius: handleTouchRadius).contains(position)) return DragHandlePosition.topMiddle;
    if (Rect.fromCircle(center: cropRect.topRight, radius: handleTouchRadius).contains(position)) return DragHandlePosition.topRight;
    if (Rect.fromCircle(center: cropRect.centerLeft, radius: handleTouchRadius).contains(position)) return DragHandlePosition.middleLeft;
    if (Rect.fromCircle(center: cropRect.centerRight, radius: handleTouchRadius).contains(position)) return DragHandlePosition.middleRight;
    if (Rect.fromCircle(center: cropRect.bottomLeft, radius: handleTouchRadius).contains(position)) return DragHandlePosition.bottomLeft;
    if (Rect.fromCircle(center: cropRect.bottomCenter, radius: handleTouchRadius).contains(position)) return DragHandlePosition.bottomMiddle;
    if (Rect.fromCircle(center: cropRect.bottomRight, radius: handleTouchRadius).contains(position)) return DragHandlePosition.bottomRight;
    if (cropRect.contains(position)) return DragHandlePosition.inside;
    return null;
  }
}
