import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_img_editor/image_editor.dart';
import 'package:image_picker/image_picker.dart';

import 'more_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor 示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();

  // 相册图片
  ui.Image? _pickerOriginal;
  ui.Image? _pickerEdited;
  String? _pickerTempPath;
  Duration? _pickerTempDuration;

  // 是否正在选择相册图片
  bool _isPickingImage = false;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor 示例'),
        actions: [
          TextButton(
            onPressed: _openMorePage,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('更多示例' , style: TextStyle(fontSize: 16 ,color: Colors.black)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIntroCard(),
            _buildPickerDemo(),
            _buildPerformanceNote(),
          ],
        ),
      ),
    );
  }

  void _openMorePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MorePage(),
      ),
    );
  }

  Card _buildIntroCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本页聚焦 image_picker 相册流程，演示如何快速打开图片编辑器并保存编辑结果。',
            ),
            SizedBox(height: 8),
            Text(
              '想了解内置 Asset、相机拍照与网络下载场景，请点击右上角“更多示例”。',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildPickerDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              title: '案例：Image Picker 相册',
              actions: [
                ElevatedButton.icon(
                  onPressed: _isPickingImage ? null : _handlePickerEdit,
                  icon: const Icon(Icons.photo_library),
                  label: Text(_isPickingImage ? '处理中...' : '选择并编辑'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '直接通过 image_picker 选择本地相册图片后进入编辑器，'
              '展示如何与外部端到端整合。',
            ),
            if (_isPickingImage)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePanel(label: '原始', image: _pickerOriginal),
                const SizedBox(width: 16),
                _buildImagePanel(label: 'ui.Image', image: _pickerEdited),
                const SizedBox(width: 16),
                _buildImagePanelFromPath(label: 'path', path: _pickerTempPath),
              ],
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_pickerOriginal, _pickerEdited),
            if (_pickerTempPath != null) ...[
              const SizedBox(height: 16),
              Text(
                '临时文件路径 (saveImageToTempFile):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(_pickerTempPath!),
              Text(
                '耗时: ${_pickerTempDuration != null ? '${_pickerTempDuration!.inMilliseconds} ms' : '--'}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String title,
    required List<Widget> actions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions,
        ),
      ],
    );
  }

  Widget _buildImagePanel({
    required String label,
    required ui.Image? image,
  }) {
    final TextStyle? captionStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade600,
            );
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image != null
                  ? RawImage(
                      image: image,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Text(
                        '暂无图片',
                        style: captionStyle,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text('像素: ${_pixelSize(image)}', style: captionStyle),
        ],
      ),
    );
  }

  Widget _buildImagePanelFromPath({
    required String label,
    required String? path,
  }) {
    final captionStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.grey.shade600,
        );
    Widget child;
    if (path != null) {
      child = Image.file(
        File(path),
        fit: BoxFit.contain,
      );
    } else {
      child = Center(
        child: Text(
          '暂无图片',
          style: captionStyle,
        ),
      );
    }
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
          ),
          const SizedBox(height: 6),
          if (path != null) Text('文件大小: ${_fileSize(path)}', style: captionStyle),
        ],
      ),
    );
  }

  Widget _buildPixelStats(ui.Image? original, ui.Image? edited) {
    final String delta = _pixelDelta(original, edited);
    final String originalMemory = _memoryUsage(original);
    final String editedMemory = _memoryUsage(edited);
    final String memoryDelta = _memoryDelta(original, edited);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '像素对比',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text('原始: ${_pixelSize(original)}'),
        Text('编辑后: ${_pixelSize(edited)}'),
        if (delta.isNotEmpty) Text(delta),
        const SizedBox(height: 8),
        Text(
          '内存估算（RGBA 32bit）',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text('原始: $originalMemory'),
        Text('编辑后: $editedMemory'),
        if (memoryDelta.isNotEmpty) Text(memoryDelta),
      ],
    );
  }

  String _pixelSize(ui.Image? image) {
    if (image == null) return '--';
    return '${image.width} x ${image.height}';
  }

  String _pixelDelta(ui.Image? original, ui.Image? edited) {
    if (original == null || edited == null) {
      return '';
    }
    final int dw = edited.width - original.width;
    final int dh = edited.height - original.height;
    String fmt(int value) => value > 0 ? '+$value' : value.toString();
    if (dw == 0 && dh == 0) {
      return '变化: 无 (像素保持不变)';
    }
    return '变化: 宽度 ${fmt(dw)}，高度 ${fmt(dh)}';
  }

  String _memoryUsage(ui.Image? image) {
    if (image == null) return '--';
    final double bytes = image.width * image.height * 4;
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  String _memoryDelta(ui.Image? original, ui.Image? edited) {
    if (original == null || edited == null) {
      return '';
    }
    final double originalPixels = original.width * original.height.toDouble();
    final double editedPixels = edited.width * edited.height.toDouble();
    final double diffBytes = (editedPixels - originalPixels) * 4;
    if (diffBytes == 0) {
      return '内存变化: 无 (像素点数量一致)';
    }
    final double diffMb = diffBytes / (1024 * 1024);
    final String sign = diffMb > 0 ? '+' : '';
    return '内存变化: $sign${diffMb.toStringAsFixed(2)} MB';
  }

  String _fileSize(String path) {
    try {
      final int bytes = File(path).lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      }
      final double kb = bytes / 1024;
      if (kb < 1024) {
        return '${kb.toStringAsFixed(1)} KB';
      }
      final double mb = kb / 1024;
      return '${mb.toStringAsFixed(2)} MB';
    } catch (error) {
      return '--';
    }
  }

  Future<void> _handlePickerEdit() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      final ui.Image image = await loadImageFromFile(picked.path);
      if (!mounted) return;
      setState(() {
        _pickerOriginal = image;
        _pickerEdited = null;
      });
      final ui.Image? result = await _openEditor(
        image,
        config: const ImageEditorConfig(
          rotateOptions: RotateOptionConfig(
            // enableFree: false,
            enableFixed: false,
          ),
          topToolbar: TopToolbarConfig(
            titleText: '相册图片编辑',
            cancelText: '取消',
            confirmText: '完成',
          ),
          compression: ImageCompressionConfig(
            enabled: true,
            scale: 0.3,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _pickerEdited = result;
      });
      await _processPickerResult(result);
      await _logImageBytes(result, 'picker');
    } catch (error) {
      _showSnack('选择图片失败: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<ui.Image?> _openEditor(
    ui.Image image, {
    ImageEditorConfig? config,
  }) {
    return Navigator.push<ui.Image?>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: image,
          config: config ?? const ImageEditorConfig(),
        ),
      ),
    );
  }

  Future<void> _logImageBytes(ui.Image image, String tag) async {
    final bytes = await convertUiImageToBytes(image);
    if (bytes == null) return;
    // 此处仅演示如何获取可直接用于上传的字节数据，可替换为实际网络请求。
    debugPrint('[image_editor_demo][$tag] export bytes=${bytes.lengthInBytes}');
  }

  /// 处理相册图片编辑结果为临时文件
  Future<void> _processPickerResult(ui.Image result) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final String? tempPath = await saveImageToTempFile(result);
    stopwatch.stop();

    setState(() {
      _pickerTempPath = tempPath;
      _pickerTempDuration = stopwatch.elapsed;
    });

    if (tempPath == null) {
      _showSnack('图片保存失败');
    } else {
      debugPrint('[image_editor_demo][picker] tempPath=$tempPath in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  Card _buildPerformanceNote() {
    return Card(
      color: Colors.blueGrey.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '性能提示',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              '· `ui.Image` 在 Flutter 中以原始 RGBA 32 位像素存储，内存占用约等于像素总数 × 4 字节，读取速度快但占用高。\n'
              '· 若目标是压缩图片体积，建议在裁剪后进一步按需缩放，并使用 JPG/PNG/WebP 编码保存或上传。\n'
              '· 对于批量压缩，可结合 `ui.PictureRecorder` 或第三方图像处理库（例如 `image` 包）在后台处理，降低内存峰值。\n'
              '· 可通过 Flutter DevTools 的 Memory 面板，或在控制台打印 `(image.width * image.height * 4 / 1024 / 1024)` 观察实时内存占用，帮助评估方案。',
            ),
          ],
        ),
      ),
    );
  }
}
