docs/
├── 01-Project-Setup-and-Core-Architecture.md
├── 02-Image-Display-and-Basic-Transformations.md
├── 03-Implementing-the-High-Fidelity-Crop-Tool.md
├── 04-Implementing-the-Rotation-Tool.md
├── 05-Implementing-the-Text-Overlay-Tool.md
└── 06-UI-and-Final-Integration.md

#### **`01-Project-Setup-and-Core-Architecture.md`**

*   **引言**: 教程目标和最终成品预览。
*   **第一步: 搭建核心骨架**
    *   创建 `ImageEditorController` 类，继承 `ChangeNotifier`。
    *   定义核心状态属性: `ui.Image _image`, `EditToolsMenu _activeTool`, `Size? _canvasSize`。
    *   创建 `ImageEditorView` (StatefulWidget)，在 `initState` 中实例化 `Controller`。
    *   讲解 `ListenableBuilder` 的作用，并用它构建基础UI (`Scaffold`)，实现状态与UI的初步绑定。
*   **第二步: 定义数据模型**
    *   创建 `models/editor_models.dart`。
    *   定义 `EditToolsMenu` 枚举，管理所有工具状态。
*   **本章小结**: 完成了项目的响应式架构基础，控制器可以管理状态，UI可以响应变化。

---

#### **`02-Image-Display-and-Basic-Transformations.md`**

*   **引言**: 目标是在画布上正确显示图片，并实现缩放。
*   **第一步: 创建绘制器 `ImageEditorPainter`**
    *   创建 `painter.dart`，定义 `ImageEditorPainter` 类继承 `CustomPainter`。
    *   在 `paint` 方法中，从 `controller` 获取 `image` 并绘制到画布中心。
*   **第二步: 实现图片的初始适配**
    *   在 `Controller` 中实现 `_initializeImageScale` 逻辑，计算图片填充屏幕的最佳初始 `_scale`。
*   **第三步: 添加手势识别**
    *   在 `ImageEditorView` 中用 `GestureDetector` 包裹 `CustomPaint`。
    *   实现 `onScaleStart`, `onScaleUpdate`, `onScaleEnd`。
    *   在 `Controller` 中添加 `_scale` 和 `_previousScale` 状态，实现图片的缩放。
    *   在 `Painter` 的 `paint` 方法中应用 `canvas.scale()` 变换。
*   **本章小结**: 图像已能显示、适配屏幕并响应用户的缩放手势。

---

#### **`03-Implementing-the-High-Fidelity-Crop-Tool.md`**

*   **引言**: 这是最核心的一节，讲解如何实现不失真的裁剪。
*   **第一步: 绘制裁剪UI**
    *   在 `Controller` 中添加 `_cropRect` 和 `isCroppingActive` 状态。
    *   在 `Painter` 中，当 `isCroppingActive` 为 `true` 时，绘制半透明遮罩、网格线和拖动控制点。
*   **第二步: 实现裁剪框的拖拽与缩放**
    *   在 `Controller` 中定义 `DragHandlePosition` 枚举。
    *   实现 `_getDragHandleForPosition` 来判断用户点击了哪个控制点。
    *   在 `onScaleStart` 和 `onScaleUpdate` 中添加裁剪框的拖拽和缩放逻辑 (`_onCropDrag...` 系列方法)。
    *   详细讲解如何根据不同控制点和宽高比约束来更新 `_cropRect`。
*   **第三步: 实现高保真裁剪 (`_applyCrop`)**
    *   **理论讲解**: 深入剖析为何不能直接截图屏幕，引出“反向映射”的核心思想。
    *   **代码实现**:
        1.  讲解如何构建从图像到屏幕的 `Matrix4` 变换。
        2.  如何使用 `Matrix4.inverted()` 求逆矩阵。
        3.  如何用逆矩阵变换 `_cropRect` 的顶点。
        4.  如何使用 `canvas.drawImageRect` 从原图提取高清像素。
        5.  如何用裁剪后的新图重置编辑器状态。
*   **本章小结**: 掌握了编辑器最复杂的裁剪功能，并理解了其背后的数学原理。

---

#### **`04-Implementing-the-Rotation-Tool.md`**

*   **引言**: 实现90度旋转和自由角度微调。
*   **第一步: 90度步进旋转**
    *   在 `Controller` 中添加 `_currentRotationAngle` 状态。
    *   实现 `rotate(90)` 方法，更新角度。
    *   在 `Painter` 的 `paint` 方法中应用 `canvas.rotate()` 变换。
*   **第二步: 自由旋转滑块 `FreeRotateSlider`**
    *   创建一个新的 `StatefulWidget`：`FreeRotateSlider`。
    *   讲解如何使用 `ListView` 或 `SingleChildScrollView` 配合 `ScrollController` 制作刻度尺。
    *   讲解如何监听滚动偏移量 `_scrollController.offset` 并将其映射为角度值。
    *   讲解滚动结束后的吸附效果 (`ScrollEndNotification` 和 `animateTo`)。
*   **第三步: 应用旋转 (`_applyRotation`)**
    *   讲解为何需要应用旋转：将变换“烘焙”到图片中。
    *   实现 `_renderRotatedImage` 方法：计算新画布大小，将原图绘制到旋转后的新画布上，生成新的 `ui.Image`。
*   **本章小结**: 完成了两种旋转模式的实现和应用。

---

#### **`05-Implementing-the-Text-Overlay-Tool.md`**

*   **引言**: 实现动态添加、编辑和移动文字图层。
*   **第一步: 数据模型与绘制**
    *   在 `models.dart` 中定义 `TextLayerData` 类。
    *   在 `Controller` 中添加 `List<TextLayerData> textLayers`。
    *   在 `Painter` 中，遍历 `textLayers`，使用 `ui.ParagraphBuilder` 和 `canvas.drawParagraph` 将文本绘制出来。
*   **第二步: 添加与编辑文本**
    *   实现 `_applyText` 方法，向 `textLayers` 列表添加新图层。
    *   在 `Controller` 中添加 `selectedTextLayerId` 状态。
    *   实现 `onTapDown` 逻辑，用于检测点击并选中文字图层。
*   **第三步: 拖动与属性修改**
    *   在 `onScaleUpdate` 中添加逻辑，当有文字被选中时，执行拖动操作。
    *   创建 `TextPropertiesToolbar`，提供颜色和大小选择器，调用 `Controller` 方法更新选中图层的属性。
*   **本章小get**: 实现了完整的文字图层系统。

---

#### **`06-UI-and-Final-Integration.md`**

*   **引言**: 将所有功能模块与UI工具栏整合，完成最终成品。
*   **第一步: 构建动态工具栏**
    *   创建 `MainToolbar` 作为主工具栏。
    *   创建 `ActiveToolMenu`，根据 `controller.activeTool` 的值动态显示不同的子工具栏（`CropToolbar`, `RotateToolbar` 等）。
    *   在 `ImageEditorView` 的 `_buildBottomToolbars` 方法中实现显示逻辑：优先显示文字属性栏 -> 其次显示激活工具栏 -> 最后显示主工具栏。
*   **第二步: 工具的激活、应用与取消**
    *   在 `Controller` 中完善 `selectTool`, `applyCurrentTool`, `cancelCurrentTool` 方法。
    *   讲解进入工具时备份状态（`_backupCropRect`, `_backupRotationAngle`）的重要性。
*   **第三步: 最终图像导出**
    *   实现 `exportImage` 和 `_captureTransformedImage` 方法。
    *   讲解导出逻辑：在一个新的画布上，**完全重现 `Painter` 的绘制过程**（绘制变换后的图片 + 绘制所有文字图层），然后生成最终图像。
*   **本章小结**: 整个编辑器组件功能完整，UI流畅，可以作为独立模块使用了。