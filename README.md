# Flutter Image Editor

一个功能强大且高度可定制的 Flutter 图片编辑组件。它提供了图片裁剪、旋转和文字叠加等核心编辑功能，采用状态驱动的响应式架构，易于集成和扩展。

![Editor Screenshot](https://user-images.githubusercontent.com/.../your-screenshot.png) <!-- 建议你在这里放一张截图 -->

---

### ✨ 核心功能

*   **🖼️ 裁剪工具**:
    *   支持自由拖拽裁剪。
    *   内置多种固定宽高比裁剪（16:9, 5:4, 1:1 等）。
    *   高保真裁剪，保证输出图片清晰度。
*   **🔄 旋转工具**:
    *   支持 90° 步进旋转。
    *   通过自定义滑块实现 -45° 到 +45° 的自由微调旋转。
*   **✍️ 文字叠加**:
    *   在图片上添加、拖动和编辑多个文本图层。
    *   支持修改文本颜色和字体大小。
    *   所见即所得，最终导出图片包含所有文字。

---

### 🏛️ 设计原理与思路

本编辑器在设计上遵循了几个关键原则，以确保其高性能、可维护性和可扩展性。

#### 1. 状态驱动的UI (State-Driven UI)
整个编辑器的核心是 `ImageEditorController`。它继承自 `ChangeNotifier`，是所有编辑状态的**唯一数据源 (Single Source of Truth)**。

*   **状态管理**: 所有用户操作（如拖动、缩放、点击按钮）都会调用 `Controller` 的方法来更新内部状态（例如 `_cropRect`, `_currentRotationAngle`, `textLayers`）。
*   **UI响应**: UI层（如 `ImageEditorView` 和各个 `Toolbar`）通过 `ListenableBuilder` 监听 `Controller` 的变化。一旦状态改变，`Controller` 会调用 `notifyListeners()`，所有监听者会自动重建，从而以最高效的方式更新界面，展示最新的状态。

#### 2. 关注点分离 (Separation of Concerns)
组件被清晰地划分为三个层次：

*   **控制层 (`Controller`)**: 负责所有业务逻辑和状态管理，不包含任何UI代码。
*   **视图层 (`View/Widgets`)**: 负责UI的展示和用户交互。例如，`MainToolbar` 负责展示工具按钮，并将用户的点击事件传递给 `Controller`。
*   **绘制层 (`Painter`)**: `ImageEditorPainter` 是一个 `CustomPainter`，它只负责一件事：根据 `Controller` 中当前的状态，将图片、裁剪框、文字等内容精确地绘制在 `Canvas` 上。

这种分离使得代码逻辑清晰，例如，如果想修改裁剪框的样式，只需修改 `ImageEditorPainter`，而无需触及任何业务逻辑。

#### 3. 高保真操作 (High-Fidelity Operations)
为了避免在编辑过程中（尤其是裁剪后）图片清晰度下降，我们采用了基于原始图像数据的处理策略。

*   **裁剪**: 当用户应用裁剪时，我们**不是对屏幕上缩放后的预览图进行截图**。相反，我们执行以下步骤：
    1.  计算一个将原始全分辨率图像坐标映射到屏幕坐标的变换矩阵（包含旋转和缩放）。
    2.  求该矩阵的**逆矩阵**。
    3.  使用逆矩阵，将屏幕上的裁剪框 `Rect` 的四个顶点**反向映射**回原始图像的坐标系中。
    4.  使用 `canvas.drawImageRect` 方法，从**原始高分辨率图像**中精确提取这个（可能倾斜的）区域，并绘制到一个新的画布上，从而生成一张全新的、与原始图像同样清晰的裁剪后图片。

*   **旋转**: 应用旋转时，我们会计算旋转后能完整容纳图像的新尺寸，在一个新的、更大的画布上绘制旋转后的原始图像，生成一张新的 `ui.Image`。

#### 4. 图层化系统 (Layered System)
文字功能被设计成一个图层系统。每个文本对象都是一个 `TextLayerData` 实例，存储在 `Controller` 的一个列表 (`textLayers`) 中。

*   **独立性**: 每个图层拥有自己独立的属性（位置、内容、颜色、大小）。
*   **渲染与导出**: `Painter` 会遍历这个列表，将每个文本图层绘制到画布上。最终导出图片时，也会执行相同的绘制逻辑，确保最终成品与预览完全一致。

---

### 🚀 如何集成

#### 方式一: Git 依赖 (推荐)
如果你的项目使用 Git 进行版本控制，这是最推荐的方式。你可以将此编辑器作为一个私有的 Git 仓库，并在你的主项目中引用它。

在你的 `pubspec.yaml` 文件中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... 其他依赖

  image_editor:
    git:
      url: git@github.com:your-username/your-image-editor-repo.git # 替换成你的仓库地址
      ref: main # 或者指定某个 tag/commit
