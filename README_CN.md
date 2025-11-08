# Image Editor Flutter SDK

[英文](./README.md)

## 概览
Image Editor 是一个可嵌入的 Flutter 图像编辑组件，提供裁剪、旋转、文字贴层等常见编辑工具，并内置面向多平台的图像加载与导出工具方法。借助响应式的 `ImageEditorController`，你可以在 App 中快速搭建类原生的图片编辑体验。

## 功能特性
- **多工具链**：裁剪（自由/16:9/5:4/1:1）、旋转（任意角度、±90°）、文字贴层。
- **状态管理**：内置历史栈，可撤销上一步操作并支持恢复初始图片。
- **高度可配置**：通过 `ImageEditorConfig` 定制工具可用性、裁剪选项、顶部工具栏文案与颜色。
- **跨平台加载**：提供 `loadImageFromAssets`、`loadImageFromFile`、`loadImageFromNetwork` 等方法，抽象平台差异。
- **像素导出**：支持将 `ui.Image` 转换为 PNG/JPEG 字节流，或在确实需要文件路径时，借助 `saveImageToTempFile` 保存临时文件。
- **手势友好**：支持双指缩放、拖拽、点击选择文本图层等操作。

## 目录结构
```text
lib/
  image_editor.dart          # 对外暴露的主入口
  controller/                # 控制器与业务处理（裁剪、旋转、文本、历史栈）
  models/                    # 数据模型与配置项
  utils/                     # 图像加载、导出、坐标转换等工具
  widgets/                   # 主视图与工具栏、画布渲染
```
更多 API 说明见 `doc/api_reference.md`。

## 安装与依赖
在你的 Flutter 项目的 `pubspec.yaml` 中加入：
```yaml
dependencies:
  flutter_img_editor: # 最新版本
```
然后执行：
```bash
flutter pub get
```

## 快速开始
```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_img_editor/image_editor.dart';


class AvatarEditorDemo extends StatefulWidget {
  const AvatarEditorDemo({super.key});

  @override
  State<AvatarEditorDemo> createState() => _AvatarEditorDemoState();
}

class _AvatarEditorDemoState extends State<AvatarEditorDemo> {
  ui.Image? _avatar;
  ui.Image? _edited;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final ui.Image image = await loadImageFromAssets('assets/sample.jpg');
    if (!mounted) return;
    setState(() {
      _avatar = image;
    });
  }

  Future<void> _openEditor() async {
    final ui.Image? avatar = _avatar;
    if (avatar == null) return;
    final ui.Image? result = await Navigator.push<ui.Image?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditor(
          image: avatar,
          config: const ImageEditorConfig(
            enableText: false,
            cropOptions: CropOptionConfig(
              enableFree: false,
              enable16By9: false,
              enable5By4: false,
              enable1By1: true,
            ),
            topToolbar: TopToolbarConfig(
              titleText: '编辑头像',
              confirmText: '完成',
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _edited = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('头像编辑示例')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _avatar == null ? null : _openEditor,
              child: const Text('打开编辑器'),
            ),
            const SizedBox(height: 16),
            if (_edited != null)
              SizedBox(
                height: 180,
                child: RawImage(image: _edited),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 1. 加载图片资源
```dart
final ui.Image image = await loadImageFromAssets('assets/sample.jpg');
```
其他加载方式：
- `loadImageFromFile(path)`：仅支持原生平台。
- `loadImageFromNetwork(url)`：支持自定义 `http.Client` 与请求头。

### 2. 嵌入编辑器
将 `ImageEditor` 作为页面主体，传入待编辑的 `ui.Image` 与可选配置。控制器会自动管理生命周期，并暴露撤销、应用等操作（详见 API 参考）。

### 3. 导出结果
```dart
final Uint8List? pngBytes = await convertUiImageToBytes(editedImage);
// 若业务场景必须使用文件路径：
final String? tempPath = await saveImageToTempFile(editedImage);
```
> **推荐做法**  
> `ui.Image` 直接渲染＋传输字节数据的效率最佳。将图片写入临时文件涉及磁盘 IO，在中端设备上实测大约需要 1～2 秒，应仅在确实需要路径时使用。

## 示例应用
示例项目位于 `example/`，展示了从内置资源、相册、相机、网络四种来源加载并编辑的流程。运行：
```bash
cd example
flutter run
```

## 常见问题
- **为什么某些裁剪比例不可用？** 若在 `ImageEditorConfig.cropOptions` 中禁用该比例，将自动隐藏对应菜单。
- **Web 平台使用 `loadImageFromFile` 报错？** Web 不支持文件系统读取，该函数会抛出 `UnsupportedError`。请使用文件选择器方案并手动解码。
- **如何监听编辑器状态？** 使用 `ImageEditorController`（见 API 文档）可获取当前工具、裁剪框、文本图层等信息。

## 贡献指南
欢迎通过 Issue 反馈或提交 Pull Request。建议在提交前运行 `flutter test` 并更新文档。

## 许可证
本项目基于 [MIT License](LICENSE)。

---
更多 API 细节、参数解释请参阅 `doc/api_reference.md`。

