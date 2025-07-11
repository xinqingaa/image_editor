// image_editor/lib/controller/image_editor_controller.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editor_models.dart';

/// 图片编辑器控制器
/// 继承自 ChangeNotifier，用于管理所有编辑状态和业务逻辑。
/// UI层通过监听此控制器来响应状态变化。
class ImageEditorController extends ChangeNotifier {
  // ----------------- 核心状态 -----------------
  ui.Image _image;
  ui.Image get image => _image;

  EditToolsMenu _activeTool = EditToolsMenu.none;
  EditToolsMenu get activeTool => _activeTool;

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

  /// 构造函数，需要传入一个初始图片
  ImageEditorController({required ui.Image image}) : _image = image;

  /// UI层在布局完成后需要调用此方法设置画布尺寸
  void setCanvasSize(Size size) {
    if (_canvasSize != size) {
      _canvasSize = size;
      // 首次设置画布尺寸时，计算图片的初始缩放以适配屏幕
      if (_scale == 1.0 && _translateX == 0.0 && _translateY == 0.0) {
        _initializeImageScale();
      }
    }
  }

  void _initializeImageScale() {
    if (_canvasSize == null) return;
    final widthRatio = _canvasSize!.width / _image.width;
    final heightRatio = _canvasSize!.height / _image.height;
    _scale = math.min(widthRatio, heightRatio);
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


  // ----------------- 工具应用与取消逻辑 -----------------

  /// 应用当前工具的修改
  Future<void> applyCurrentTool() async {
    if (isCropTool(_activeTool)) {
      await _applyCrop();
    } else if (isRotateTool(_activeTool)) {
      await _applyRotation();
    }
    // 关闭工具菜单
    _activeTool = EditToolsMenu.none;
    notifyListeners();
  }

  /// 取消当前工具的修改
  void cancelCurrentTool() {
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
    if (_activeTool == tool) {
      // 如果重复点击同一个工具，则关闭它
      cancelCurrentTool();
      return;
    }

    _activeTool = tool;

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
    _activeTool = tool;
    _initializeCropRect(aspectRatio: aspectRatio);
    notifyListeners();
  }


  /// 旋转图片（按指定角度）
  void rotate(double degrees) {
    _currentRotationAngle += (degrees * math.pi / 180.0);
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
    if (isCroppingActive) {
      _onCropDragStart(details.localFocalPoint);
    } else {
      _previousScale = _scale;
    }
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
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
    if (isCroppingActive) {
      _onCropDragEnd();
    }
  }

  // ----------------- 私有方法：内部逻辑实现 -----------------

  // 应用裁剪
  Future<void> _applyCrop() async {
    if (_cropRect == null || _canvasSize == null) return;

    // 1. 计算将图像坐标映射到屏幕坐标的变换矩阵
    final Matrix4 matrixToScreen = Matrix4.identity()
      ..translate(_canvasSize!.width / 2, _canvasSize!.height / 2)
      ..rotateZ(_currentRotationAngle)
      ..scale(_scale, _scale)
      ..translate(-_image.width / 2, -_image.height / 2);

    // 2. 计算其逆矩阵，用于将屏幕坐标映射回原始图像坐标
    final Matrix4 screenToImage = Matrix4.inverted(matrixToScreen);

    // 3. 将屏幕上的裁剪框的四个角通过逆矩阵转换到原始图像的坐标系中
    final Offset srcTopLeft = MatrixUtils.transformPoint(screenToImage, _cropRect!.topLeft);
    final Offset srcTopRight = MatrixUtils.transformPoint(screenToImage, _cropRect!.topRight);
    final Offset srcBottomLeft = MatrixUtils.transformPoint(screenToImage, _cropRect!.bottomLeft);
    final Offset srcBottomRight = MatrixUtils.transformPoint(screenToImage, _cropRect!.bottomRight);

    // 4. 根据转换后的四个点，计算出在原始图像上对应的源矩形(srcRect)
    // 这个矩形包围了用户在屏幕上选择的区域在原图上的所有像素
    final double srcLeft = math.min(srcTopLeft.dx, math.min(srcTopRight.dx, math.min(srcBottomLeft.dx, srcBottomRight.dx)));
    final double srcTop = math.min(srcTopLeft.dy, math.min(srcTopRight.dy, math.min(srcBottomLeft.dy, srcBottomRight.dy)));
    final double srcRight = math.max(srcTopLeft.dx, math.max(srcTopRight.dx, math.max(srcBottomLeft.dx, srcBottomRight.dx)));
    final double srcBottom = math.max(srcTopLeft.dy, math.max(srcTopRight.dy, math.max(srcBottomLeft.dy, srcBottomRight.dy)));
    final Rect srcRect = Rect.fromLTRB(srcLeft, srcTop, srcRight, srcBottom);

    // 5. 准备进行高精度绘制
    final recorder = ui.PictureRecorder();
    // 目标画布的大小就是屏幕上裁剪框的大小
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _cropRect!.width, _cropRect!.height));

    // 目标矩形(dstRect)覆盖整个新画布
    final Rect dstRect = Rect.fromLTWH(0, 0, _cropRect!.width, _cropRect!.height);

    // 使用最高质量的滤波
    final Paint paint = Paint()..filterQuality = FilterQuality.high;

    // 6. [魔法发生的地方] 使用 drawImageRect 从原始 _image 中提取 srcRect 的像素，
    // 并将其绘制到新画布的 dstRect 区域。
    // Flutter会处理好因旋转导致的倾斜矩形的采样问题。
    canvas.drawImageRect(_image, srcRect, dstRect, paint);

    // 7. 生成最终的高清裁剪图
    // 注意：这里输出的图片尺寸是 _cropRect 的尺寸，但其像素密度是来自原图的，所以非常清晰。
    final ui.Image croppedImage = await recorder.endRecording().toImage(
      _cropRect!.width.round(),
      _cropRect!.height.round(),
    );

    // 8. 用裁剪后的高清图片替换当前图片，并重置所有变换
    resetTransformations(newImage: croppedImage);

    // 清理裁剪状态
    _cropRect = null;
    _backupCropRect = null;
  }

  ///  应用旋转
  Future<void> _applyRotation() async {
    if (_currentRotationAngle == _backupRotationAngle) {
      // 如果角度没有变化，则无需操作
      return;
    }
    // 渲染一个只应用了旋转的新图片
    final rotatedImage = await _renderRotatedImage();
    if (rotatedImage != null) {
      // 用旋转后的图片替换，并重置所有变换
      resetTransformations(newImage: rotatedImage);
    }
  }


  /// [私有] 渲染一个只包含旋转变换的新图片
  Future<ui.Image> _renderRotatedImage() async {
    final angle = _currentRotationAngle;

    // 计算旋转后新图片的边界框大小
    final sinAngle = math.sin(angle).abs();
    final cosAngle = math.cos(angle).abs();
    final newWidth = _image.width * cosAngle + _image.height * sinAngle;
    final newHeight = _image.width * sinAngle + _image.height * cosAngle;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, newWidth, newHeight));

    // 将画布原点移动到新画布中心
    canvas.translate(newWidth / 2, newHeight / 2);
    // 旋转
    canvas.rotate(angle);
    // 将图片中心对齐到原点并绘制
    canvas.drawImage(_image, Offset(-_image.width / 2, -_image.height / 2), Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(newWidth.round(), newHeight.round());
  }


  /// 裁剪逻辑 会牺牲清晰度
  /// 会在缩放的基础上裁剪  本质上是在这个低分辨率的预览图上，再截取出一小块（_cropRect） 所以导致清晰度骤降
  Future<ui.Image?> _captureCroppedImage() async {
    // ... [此方法逻辑不变，依然是从屏幕视图中抠出cropRect区域] ...
    if (_cropRect == null || !isCroppingActive || _canvasSize == null) return null;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas captureCanvas = Canvas(recorder, Rect.fromLTWH(0, 0, _cropRect!.width.roundToDouble(), _cropRect!.height.roundToDouble()));

    Matrix4 matrixToScreen = Matrix4.identity();
    final double canvasWidgetCenterX = _canvasSize!.width / 2;
    final double canvasWidgetCenterY = _canvasSize!.height / 2;

    matrixToScreen.translate(canvasWidgetCenterX, canvasWidgetCenterY);
    matrixToScreen.rotateZ(_currentRotationAngle);
    matrixToScreen.scale(_scale, _scale);
    matrixToScreen.translate(-_image.width / 2, -_image.height / 2);

    Matrix4 finalTransformForCapture = Matrix4.translationValues(-_cropRect!.left, -_cropRect!.top, 0);
    finalTransformForCapture.multiply(matrixToScreen);

    captureCanvas.transform(finalTransformForCapture.storage);
    captureCanvas.drawImage(_image, Offset.zero, Paint());

    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(_cropRect!.width.toInt(), _cropRect!.height.toInt());
  }

  /// [新增] 捕获当前所有变换（旋转、缩放、平移）后的最终图像
  Future<ui.Image> _captureTransformedImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _canvasSize!.width, _canvasSize!.height));

    // 完全复制 painter 中的绘制逻辑
    final paint = Paint();
    final canvasCenterX = _canvasSize!.width / 2;
    final canvasCenterY = _canvasSize!.height / 2;
    canvas.save();
    canvas.translate(canvasCenterX, canvasCenterY);
    canvas.rotate(_currentRotationAngle);
    canvas.scale(_scale, _scale);
    canvas.drawImage(_image, Offset(-_image.width / 2, -_image.height / 2), paint);
    canvas.restore();

    final picture = recorder.endRecording();
    return await picture.toImage(_canvasSize!.width.toInt(), _canvasSize!.height.toInt());
  }

  void _initializeCropRect({double? aspectRatio}) {
    if (_canvasSize == null) return;

    final double initialCropWidth;
    final double initialCropHeight;

    if (aspectRatio != null) {
      double w = _canvasSize!.width * 0.8;
      double h = w / aspectRatio;
      if (h > _canvasSize!.height * 0.8) {
        h = _canvasSize!.height * 0.8;
        w = h * aspectRatio;
      }
      initialCropWidth = w;
      initialCropHeight = h;
    } else {
      initialCropWidth = math.min(_canvasSize!.width, _canvasSize!.height) * 0.8;
      initialCropHeight = initialCropWidth;
    }

    final double left = (_canvasSize!.width - initialCropWidth) / 2;
    final double top = (_canvasSize!.height - initialCropHeight) / 2;
    _cropRect = Rect.fromLTWH(left, top, initialCropWidth, initialCropHeight);
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
    final Size canvasSize = _canvasSize!;

    // =======================================================================
    // == 完整复制并迁移你原来的 _onCropDragUpdate 核心逻辑
    // =======================================================================
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
      default:
        break;
    }

    _cropRect = _clampRectToCanvas(newRect, canvasSize);
  }

  void _onCropDragEnd() {
    _activeDragHandle = null;
    _dragStartPoint = null;
    _initialCropRectOffsetForDrag = null;
    notifyListeners();
  }

  Rect _clampRectToCanvas(Rect rect, Size canvasSize) {
    double left = rect.left.clamp(0.0, canvasSize.width - rect.width);
    double top = rect.top.clamp(0.0, canvasSize.height - rect.height);
    double width = rect.width.clamp(_minCropSize, canvasSize.width - left);
    double height = rect.height.clamp(_minCropSize, canvasSize.height - top);
    return Rect.fromLTWH(left, top, width, height);
  }

  double? _getCurrentAspectRatio() {
    switch (_activeTool) {
      case EditToolsMenu.crop16_9:
        return 16.0 / 9.0;
      case EditToolsMenu.crop5_4:
        return 5.0 / 4.0;
      case EditToolsMenu.crop1_1:
        return 1.0;
      default:
        return null;
    }
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
