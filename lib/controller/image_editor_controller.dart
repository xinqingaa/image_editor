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

  // ----------------- 公共方法：由UI层调用 -----------------

  /// 切换主工具
  void selectTool(EditToolsMenu tool) {
    // 如果重复点击同一个类型的工具，则关闭它
    if ((isCropTool(tool) && isCroppingActive) ||
        (isRotateTool(tool) && isRotateTool(_activeTool)) ||
        (tool == EditToolsMenu.text && _activeTool == EditToolsMenu.text)) {
      _activeTool = EditToolsMenu.none;
    } else {
      _activeTool = tool;
    }

    if (isCroppingActive) {
      _initializeCropRect(aspectRatio: _getCurrentAspectRatio());
    } else {
      _cropRect = null;
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
  Future<ui.Image?> exportImage() async {
    if (isCroppingActive && _cropRect != null) {
      return await _captureCroppedImage();
    }
    // 如果不是裁剪模式，可以根据需要实现导出应用了旋转和缩放的图片
    // 这里为简化，直接返回当前图片（未应用变换）
    // 若要导出带变换的图片，需要一个类似_captureCroppedImage的渲染过程
    return _image;
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

  Future<ui.Image?> _captureCroppedImage() async {
    if (_cropRect == null || !isCroppingActive) return null;

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
}
