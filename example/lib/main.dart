import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_img_editor/image_editor.dart';
import 'package:image_picker/image_picker.dart';

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

  // 内置图片
  ui.Image? _assetOriginal;
  ui.Image? _assetEdited;

  // 相册图片
  ui.Image? _pickerOriginal;
  ui.Image? _pickerEdited;
  String? _pickerTempPath;
  Duration? _pickerTempDuration;

  // 相机图片
  ui.Image? _cameraOriginal;
  ui.Image? _cameraEdited;

  // 网络图片
  ui.Image? _networkOriginal;
  ui.Image? _networkEdited;

  // 是否正在选择相册图片
  bool _isPickingImage = false;
  // 是否正在使用相机
  bool _isCapturingImage = false;
  // 是否正在下载网络图片
  bool _isFetchingNetwork = false;

  // 网络图片URL
  static const String _networkImageUrl =
      'https://img0.baidu.com/it/u=55569000,880805428&fm=253&app=138&f=JPEG?w=500&h=500';

  @override
  void initState() {
    super.initState();
    _warmUpAssetImage();
  }

  Future<void> _warmUpAssetImage() async {
    try {
      final ui.Image image = await loadImageFromAssets('assets/sample.jpg');
      if (!mounted) return;
      setState(() {
        _assetOriginal = image;
      });
    } catch (error) {
      _showSnack('加载内置图片失败: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '以下示例展示如何将图片编辑器嵌入到不同来源的图片工作流中，'
              '并展示编辑前后的视觉、像素与内存占用对比。',
            ),
            const SizedBox(height: 8),
            const Text(
              '''小贴士：示例直接调用 SDK 暴露的 `loadImageFromAssets`、`loadImageFromFile`、`loadImageFromNetwork` 与 `convertUiImageToBytes` 方法。
在实际工程中需确保拥有相册/相机/网络权限；在 Web 平台上，文件读取接口会抛出 UnsupportedError，建议捕获并给用户友好提示。''',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildAssetDemo(),
            _buildDivider(),
            _buildCameraDemo(),
            _buildDivider(),
            _buildPickerDemo(),
            _buildDivider(),
            _buildNetworkDemo(),
            _buildDivider(),
            _buildPerformanceNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 0.5),
    );
  }

  Card _buildAssetDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              title: '案例一：内置 Asset',
              actions: [
                ElevatedButton.icon(
                  onPressed: _assetOriginal == null ? null : _handleAssetEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('打开编辑器'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '预置 Assets 中的示例图片，模拟头像编辑场景。'
              '演示自定义工具栏文案、禁用文字工具，仅保留 1:1 裁剪。',
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              original: _assetOriginal,
              edited: _assetEdited,
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_assetOriginal, _assetEdited),
          ],
        ),
      ),
    );
  }

  Card _buildCameraDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              title: '案例二：相机拍照',
              actions: [
                ElevatedButton.icon(
                  onPressed: _isCapturingImage ? null : _handleCameraEdit,
                  icon: const Icon(Icons.photo_camera),
                  label: Text(_isCapturingImage ? '启动中...' : '拍照并编辑'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '使用 image_picker 调起系统相机拍摄图片后立即进入编辑器，'
              '适合实时拍摄并进行裁剪、贴图、旋转等操作。',
            ),
            if (_isCapturingImage)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              original: _cameraOriginal,
              edited: _cameraEdited,
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_cameraOriginal, _cameraEdited),
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
              title: '案例二：Image Picker 相册',
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
              Text('临时文件路径 (saveImageAsTempPathString):',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              SelectableText(_pickerTempPath!),
              Text('耗时: ${_pickerTempDuration != null ? '${_pickerTempDuration!.inMilliseconds} ms' : '--'}'),
            ],
          ],
        ),
      ),
    );
  }

  Card _buildNetworkDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              title: '案例三：网络图片',
              actions: [
                ElevatedButton.icon(
                  onPressed:
                      _isFetchingNetwork ? null : () => _handleNetworkEdit(),
                  icon: const Icon(Icons.cloud_download),
                  label: Text(_isFetchingNetwork ? '下载中...' : '下载并编辑'),
                ),
                TextButton(
                  onPressed: (_networkOriginal == null || _isFetchingNetwork)
                      ? null
                      : () => _handleNetworkEdit(refresh: false),
                  child: const Text('再次编辑'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '示例地址：$_networkImageUrl',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const Text(
              '从网络加载一张高清图像，保留所有工具，演示下载—编辑—回传全流程。',
            ),
            if (_isFetchingNetwork)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              original: _networkOriginal,
              edited: _networkEdited,
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_networkOriginal, _networkEdited),
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

  Widget _buildComparisonRow({
    required ui.Image? original,
    required ui.Image? edited,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePanel(label: '原始', image: original),
        const SizedBox(width: 16),
        _buildImagePanel(label: '编辑后', image: edited),
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

  Future<void> _handleAssetEdit() async {
    final ui.Image? original = _assetOriginal;
    if (original == null) {
      _showSnack('内置图片尚未准备好');
      return;
    }
    final ui.Image? result = await _openEditor(
      original,
      config: const ImageEditorConfig(
        enableRotate: true,
        enableText: false,
        cropOptions: CropOptionConfig(
          enableFree: false,
          enable16By9: false,
          enable5By4: false,
          enable1By1: true,
        ),
        topToolbar: TopToolbarConfig(
          titleText: '头像编辑',
          cancelText: '返回',
          confirmText: '完成',
          confirmTextColor: Colors.orange,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _assetEdited = result;
    });
    await _logImageBytes(result, 'asset');
  }

  Future<void> _handleCameraEdit() async {
    if (_isCapturingImage) return;
    setState(() {
      _isCapturingImage = true;
    });
    try {
      final XFile? captured = await _picker.pickImage(source: ImageSource.camera);
      if (captured == null) {
        return;
      }

      final ui.Image image = await loadImageFromFile(captured.path);
      if (!mounted) return;
      setState(() {
        _cameraOriginal = image;
        _cameraEdited = null;
      });

      final ui.Image? result = await _openEditor(
        image,
        config: const ImageEditorConfig(
          topToolbar: TopToolbarConfig(
            titleText: '相机图片编辑',
            cancelText: '取消',
            confirmText: '完成',
          ),
        ),
      );

      if (!mounted || result == null) return;
      setState(() {
        _cameraEdited = result;
      });
      await _logImageBytes(result, 'camera');
    } catch (error) {
      _showSnack('拍照失败: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isCapturingImage = false;
      });
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
          topToolbar: TopToolbarConfig(
            titleText: '相册图片编辑',
            cancelText: '取消',
            confirmText: '完成',
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

  Future<void> _handleNetworkEdit({bool refresh = true}) async {
    if (_isFetchingNetwork) return;
    setState(() {
      _isFetchingNetwork = true;
    });
    try {
      ui.Image image;
      if (_networkOriginal != null && !refresh) {
        image = _networkOriginal!;
      } else {
        image = await loadImageFromNetwork(_networkImageUrl);
        if (!mounted) return;
        setState(() {
          _networkOriginal = image;
          if (refresh) {
            _networkEdited = null;
          }
        });
      }

      final ui.Image? result = await _openEditor(
        image,
        config: const ImageEditorConfig(
          
          topToolbar: TopToolbarConfig(
            titleText: '网络图片编辑',
            cancelText: '返回',
            confirmText: '完成',
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _networkEdited = result;
      });
      await _logImageBytes(result, 'network');
    } catch (error) {
      _showSnack('下载网络图片失败: $error');
    } finally {

      if (!mounted) return;
      setState(() {
        _isFetchingNetwork = false;
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
    final String? tempPath = await ImageExporter.saveImageAsTempPathString(result);
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
