# Image Editor Flutter SDK

[中文](./README_CN.md)

## Overview
Image Editor is an embeddable Flutter component that brings cropping, rotation, and text overlays to your app. It ships with platform-friendly image loading/export helpers and a reactive `ImageEditorController`, enabling native-like editing workflows in minutes.

## Highlights
- **Rich toolset**: cropping (free, 16:9, 5:4, 1:1), rotation (free angle, ±90°), and text layers.
- **Stateful workflow**: built-in history stack with undo and reset-to-original.
- **Highly configurable**: tune tool availability, crop presets, and top toolbar copy/colors via `ImageEditorConfig`.
- **Cross-platform loaders**: helpers such as `loadImageFromAssets`, `loadImageFromFile`, and `loadImageFromNetwork` hide platform differences.
- **Pixel export**: convert edited `ui.Image` instances to PNG/JPEG bytes, optionally apply `ImageCompressionConfig` scaling, or persist them via `saveImageToTempFile` when a file path is required.
- **Gesture friendly**: pinch-to-zoom, drag, and tap to select text layers.

## Project Layout
```text
lib/
  image_editor.dart          # Package entry point
  controller/                # Core controller, crop/rotation/text/history handlers
  models/                    # Configurations and data models
  utils/                     # Image loading, exporting, coordinate helpers
  widgets/                   # Main view, toolbars, and painter
```
See `doc/api_reference.md` for detailed API descriptions.

## Installation
Add to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_img_editor:
    git:
      url: https://github.com/your-org/flutter_img_editor.git
```
Run:
```bash
flutter pub get
```

## Quick Start
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
              titleText: 'Edit Avatar',
              confirmText: 'Done',
            ),
            compression: ImageCompressionConfig(
              enabled: true,
              scale: 0.5,
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
      appBar: AppBar(title: const Text('Avatar Editor Demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _avatar == null ? null : _openEditor,
              child: const Text('Open Editor'),
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

### 1. Load an image resource
```dart
final ui.Image image = await loadImageFromAssets('assets/sample.jpg');
```
Other entry points:
- `loadImageFromFile(path)`: available on IO-capable platforms only.
- `loadImageFromNetwork(url)`: accepts custom `http.Client` and headers.

### 2. Embed the editor
Place `ImageEditor` in your widget tree, passing the `ui.Image` to edit alongside optional configuration. The controller manages lifecycle, undo/apply operations, and exposes the latest editing state (see API reference).

### 3. Export the result
```dart
final Uint8List? pngBytes = await convertUiImageToBytes(editedImage);
// For workflows that absolutely need a path, use:
final String? tempPath = await saveImageToTempFile(
  editedImage,
  compression: const ImageCompressionConfig(scale: 0.5),
);
```
> **Recommendation**  
> Prefer rendering `ui.Image` directly or sending `Uint8List` buffers. Converting to a temporary file path blocks on disk IO and may take ~1–2 seconds on mid-range devices.

### 4. Optional: enable export-time compression
```dart
const compression = ImageCompressionConfig(
  enabled: true,
  scale: 0.3, // downscale width/height
  format: ui.ImageByteFormat.png,
);

final ui.Image? result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ImageEditor(
      image: avatar,
      config: ImageEditorConfig(compression: compression),
    ),
  ),
);

final Uint8List? compressedBytes =
    await convertUiImageToBytes(result!, compression: compression);
```
> Use `scale` to shrink pixel dimensions and reduce memory/disk footprint. `enabled` defaults to `true`, and values in (0,1] take effect. PNG remains lossless; apply custom pipelines if you need additional compression.

## Example App
The `example/` folder showcases asset, gallery, camera, and network flows. Run it with:
```bash
cd example
flutter run
```

## FAQ
- **Why is a crop ratio missing?** Disable a ratio in `ImageEditorConfig.cropOptions` and it disappears from the toolbar.
- **`loadImageFromFile` throws on Web?** Web lacks direct file system access; the helper throws `UnsupportedError`. Use a file picker and manually decode bytes.
- **How do I observe editor state?** Use `ImageEditorController` to read active tool, crop rect, text layers, and more.

## Contributing
Issues and pull requests are welcome. Please run `flutter test` and update documentation before submitting changes.

## License
Released under the [MIT License](LICENSE).

---
Extra API details live in `doc/api_reference.md`.

