# Image Editor API Reference

本文件列出了 `package:flutter_img_editor` 中的主要对外 API，包含用途说明、关键参数与使用要点。示例均采用 Dart 语言。

## Widgets

### ImageEditor
- **类型**：`StatelessWidget`
- **描述**：编辑器对外暴露的入口 Widget，内部创建 `ImageEditorController` 并挂载主要 UI。
- **构造参数**：
  - `ui.Image image` *(必选)*：待编辑的位图，建议提前解码完毕。
  - `ImageEditorConfig config` *(可选，默认 `const ImageEditorConfig()`)*：工具可用性与文案配置。
- **使用提示**：
  - Widget 内部会在 `dispose` 时释放控制器，无需手动管理。
  - 推荐搭配 `FutureBuilder` 或 `ValueListenableBuilder` 先加载/缓存 `ui.Image`。

## 配置模型

### ImageEditorConfig
- 控制工具启用状态，并组合以下配置项：
  - `enableCrop` *(bool)*：启用裁剪工具，默认 `true`。
  - `enableRotate` *(bool)*：启用旋转工具，默认 `true`。
  - `enableText` *(bool)*：启用文本工具，默认 `true`。
  - `cropOptions` *(CropOptionConfig)*：裁剪比例开关集合。
  - `topToolbar` *(TopToolbarConfig)*：顶部工具栏文案/配色。
  - `compression` *(ImageCompressionConfig?)*：导出时的压缩配置，`null` 时保持原尺寸。
- **常见用法**：禁用文本工具、限制裁剪为 1:1、重写确认按钮文本等。

### CropOptionConfig
- 控制各裁剪比例是否可用：
  - `enableFree`
  - `enable16By9`
  - `enable5By4`
  - `enable1By1`
- 全部默认 `true`。禁用后对应按钮会在 UI 中隐藏。

### TopToolbarConfig
- 自定义顶部栏文案与颜色：
  - `cancelText`, `titleText`, `confirmText`
  - `cancelTextColor`, `titleTextColor`, `confirmTextColor`, `backgroundColor`
- 为空时使用组件内置默认值。

### ImageCompressionConfig
- 控制导出阶段的像素缩放与编码：
  - `enabled` *(bool，默认 `true`)*：是否启用压缩逻辑。
  - `scale` *(double?，默认 `0.5`)*：宽高缩放比例，取值需大于 0；`null` 或 ≥ 1 时维持原尺寸。
  - `format` *(ui.ImageByteFormat，默认 `png`)*：输出格式；当前实现推荐使用 PNG。
- 可传入 `ImageEditorConfig.compression`、`convertUiImageToBytes` 或 `saveImageToTempFile` 的 `compression` 参数共用一套配置。

### TextLayerData
- 代表单个文本图层的数据结构：
  - `id`：唯一标识，可用于外部定位。
  - `text`：文本内容。
  - `position`：左上角坐标（画布坐标系）。
  - `color`：文本颜色。
  - `fontSize`：字号（逻辑像素）。
  - `isSelected`：是否被当前选中。

## 控制器

### ImageEditorController
> `ChangeNotifier`，由 `ImageEditor` 自动创建。可通过依赖注入或全局键暴露给外部以实现高级控制。

#### 关键属性（只读）
- `ui.Image image`：当前画布上的图像。
- `EditToolsMenu activeTool`：当前激活的工具。
- `Size? canvasSize`：绘制区域尺寸。
- `double currentRotationAngle`：当前旋转角度（弧度）。
- `Rect? cropRect`：裁剪框位置。
- `List<TextLayerData> textLayers`：所有文本层。
- `String? selectedTextLayerId`：当前选中的文本层 ID。
- `bool isBusy`：是否正在应用某个耗时操作。
- `bool canUndo`：是否可撤销。
- `bool canResetToOriginal`：是否可恢复至初始状态。

#### 主要方法
- `void selectTool(EditToolsMenu tool)`：切换主工具，重复选择可退出。
- `void selectCropTool(EditToolsMenu tool, {double? aspectRatio})`：直接进入指定裁剪比例。
- `Future<void> applyCurrentTool()`：应用当前工具结果，写入历史栈。
- `void cancelCurrentTool()`：退出工具并恢复进入工具前状态。
- `void resetToOriginal()`：重置为初始图片/状态。
- `void undoLastOperation()`：撤销最近一次应用。
- `void addOrSelectTextLayer()` / `void deleteSelectedTextLayer()`：由文本工具栏内部调用，管理文本层。
- `void onTapDown / onScaleStart / onScaleUpdate / onScaleEnd`：供手势识别调用，通常由 `ImageEditorView` 转发。
- `Future<ui.Image> exportImage()`：生成应用裁剪与旋转的最终图像（如在 `image_exporter.dart` 中实现）。

> 更多低层 Handler（`crop_handler.dart`, `rotation_handler.dart`, `text_layer_manager.dart`）通常无需直接访问，如需扩展可阅读源码。

## 工具方法 (`utils/`)

### `loadImageFromAssets(String assetPath, {AssetBundle? bundle})`
- 从 `AssetBundle` 加载资源并解码为 `ui.Image`。
- 失败时抛出 `FlutterError` 或 `StateError`。

### `loadImageFromFile(String path)`
- 调用原生文件系统读取图片并解码。
- 在 Web 平台会抛出 `UnsupportedError`，需自行捕获。

### `loadImageFromNetwork(String url, {http.Client? client, Map<String, String>? headers})`
- 发起 HTTP GET 请求并解码响应字节。
- 当响应码非 200 时抛出 `http.ClientException`。
- 若传入自定义 `client`，调用方负责关闭。

### `Future<ui.Image> decodeImageFromBytes(Uint8List bytes)`
- 将图片原始字节解码为 `ui.Image`。
- 常与自定义来源（文件选择器、相册插件）结合使用。

### `Future<Uint8List?> convertUiImageToBytes(ui.Image image, {ImageCompressionConfig? compression})`
- 将 `ui.Image` 按需缩放后编码为字节流；compression 为空时保持原始尺寸与默认 PNG。
- 若底层 `toByteData` 返回 `null`，则返回 `null`。

### `Future<String?> saveImageToTempFile(ui.Image image, {ImageCompressionConfig? compression, String prefix = 'image'})`
- 依赖 `path_provider` 将图像缓存到临时目录，并返回生成的文件路径字符串。
- 若编码失败（`convertUiImageToBytes` 返回 `null`），则返回 `null`。
- 支持传入 `compression` 与 `convertUiImageToBytes` 保持一致的压缩策略。
- 适合在分享、上传前快速获取一张本地临时图片。
- **耗时提示**：保存至磁盘涉及编码与写入，实机（中端设备）测试大约需要 1~2 秒。推荐优先使用 `ui.Image` 直接渲染或传输 `Uint8List`，仅在确实需要文件路径时调用。

## 枚举

### EditToolsMenu
- `none`
- `cropFree`, `crop16_9`, `crop5_4`, `crop1_1`
- `rotateFree`, `rotate_90`, `rotate_90_`
- `text`

### DragHandlePosition
- 用于裁剪框控制点定位：`topLeft`, `topMiddle`, ..., `inside`。

## 平台注意事项
- Web 平台无文件读取能力，调用 `loadImageFromFile` 会抛出异常；可以通过 `<input type="file">` 获取 `Uint8List` 后传入 `decodeImageFromBytes`。
- iOS/Android 使用相册或相机前需在宿主应用申请权限。
- 导出图像通常需要额外的内存开销，建议在后台隔离中处理大量批量任务。

---
更多进阶示例可参考 `example/` 目录与源代码注释。

