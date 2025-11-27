import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_img_editor/image_editor.dart';
import 'package:image_picker/image_picker.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final ImagePicker _picker = ImagePicker();

  ui.Image? _assetOriginal;
  ui.Image? _assetEdited;
  String? _assetTempPath;
  Duration? _assetTempDuration;

  ui.Image? _cameraOriginal;
  ui.Image? _cameraEdited;
  String? _cameraTempPath;
  Duration? _cameraTempDuration;
  bool _isCapturingImage = false;

  ui.Image? _networkOriginal;
  ui.Image? _networkEdited;
  String? _networkTempPath;
  Duration? _networkTempDuration;
  bool _isFetchingNetwork = false;

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
      appBar: AppBar(
        title: const Text('更多示例'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewCard(),
            _buildAssetDemo(),
            _buildDivider(),
            _buildCameraDemo(),
            _buildDivider(),
            _buildNetworkDemo(),
            _buildDivider(),
            _buildPerformanceNote(),
          ],
        ),
      ),
    );
  }

  Card _buildOverviewCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '以下示例展示如何将图片编辑器嵌入 Asset、相机与网络图片工作流中，'
              '并对比 ui.Image 渲染与写入临时文件的差异。',
            ),
            SizedBox(height: 8),
            Text(
              '''小贴士：
· 示例直接调用 SDK 暴露的 `loadImageFromAssets`、`loadImageFromFile`、`loadImageFromNetwork`、`convertUiImageToBytes` 与 `saveImageToTempFile`。
· 推荐优先使用 `ui.Image` 渲染或传输字节数据；生成临时文件路径会进行编码与磁盘写入，实机大约耗时 1～2 秒。
· 在实际工程中需确保拥有相册/相机/网络权限；Web 平台调用文件相关 API 会抛出 `UnsupportedError`，请捕获后给用户友好提示。''',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
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
              '预置 Assets 中的示例图片，模拟头像编辑场景，演示自定义裁剪与工具栏配置。',
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePanel(label: '原始', image: _assetOriginal),
                const SizedBox(width: 16),
                _buildImagePanel(label: 'ui.Image', image: _assetEdited),
                const SizedBox(width: 16),
                _buildImagePanelFromPath(label: 'path', path: _assetTempPath),
              ],
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_assetOriginal, _assetEdited),
            if (_assetTempPath != null) ...[
              const SizedBox(height: 16),
              Text(
                '临时文件路径 (saveImageToTempFile):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(_assetTempPath!),
              Text(
                '耗时: ${_assetTempDuration != null ? '${_assetTempDuration!.inMilliseconds} ms' : '--'}',
              ),
            ],
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
              '调起系统相机拍照后立即进入编辑器，适合实时拍摄与快速处理。',
            ),
            if (_isCapturingImage)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePanel(label: '原始', image: _cameraOriginal),
                const SizedBox(width: 16),
                _buildImagePanel(label: 'ui.Image', image: _cameraEdited),
                const SizedBox(width: 16),
                _buildImagePanelFromPath(label: 'path', path: _cameraTempPath),
              ],
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_cameraOriginal, _cameraEdited),
            if (_cameraTempPath != null) ...[
              const SizedBox(height: 16),
              Text(
                '临时文件路径 (saveImageToTempFile):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(_cameraTempPath!),
              Text(
                '耗时: ${_cameraTempDuration != null ? '${_cameraTempDuration!.inMilliseconds} ms' : '--'}',
              ),
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
              '下载高清图后进入编辑器，保留全部工具栏，完整演示下载—编辑—回传流程。',
            ),
            if (_isFetchingNetwork)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePanel(label: '原始', image: _networkOriginal),
                const SizedBox(width: 16),
                _buildImagePanel(label: 'ui.Image', image: _networkEdited),
                const SizedBox(width: 16),
                _buildImagePanelFromPath(label: 'path', path: _networkTempPath),
              ],
            ),
            const SizedBox(height: 12),
            _buildPixelStats(_networkOriginal, _networkEdited),
            if (_networkTempPath != null) ...[
              const SizedBox(height: 16),
              Text(
                '临时文件路径 (saveImageToTempFile):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(_networkTempPath!),
              Text(
                '耗时: ${_networkTempDuration != null ? '${_networkTempDuration!.inMilliseconds} ms' : '--'}',
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
        compression: ImageCompressionConfig(
          enabled: true,
          scale: 0.8,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _assetEdited = result;
    });
    await _processResult(
      result: result,
      tag: 'asset',
      assign: (path, duration) {
        _assetTempPath = path;
        _assetTempDuration = duration;
      },
    );
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
        _cameraTempPath = null;
        _cameraTempDuration = null;
      });

      final ui.Image? result = await _openEditor(
        image,
        config: const ImageEditorConfig(
          rotateOptions: RotateOptionConfig(
            enableFree: false,
            enableFixed: true,
          ),
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
      await _processResult(
        result: result,
        tag: 'camera',
        assign: (path, duration) {
          _cameraTempPath = path;
          _cameraTempDuration = duration;
        },
      );
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
            _networkTempPath = null;
            _networkTempDuration = null;
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
      await _processResult(
        result: result,
        tag: 'network',
        assign: (path, duration) {
          _networkTempPath = path;
          _networkTempDuration = duration;
        },
      );
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

  Future<void> _processResult({
    required ui.Image result,
    required String tag,
    required void Function(String? path, Duration duration) assign,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final String? tempPath = await saveImageToTempFile(result);
    stopwatch.stop();

    if (!mounted) return;
    setState(() {
      assign(tempPath, stopwatch.elapsed);
    });

    if (tempPath == null) {
      _showSnack('图片保存失败');
    } else {
      debugPrint(
        '[image_editor_demo][$tag] tempPath=$tempPath in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<void> _logImageBytes(ui.Image image, String tag) async {
    final bytes = await convertUiImageToBytes(image);
    if (bytes == null) return;
    debugPrint('[image_editor_demo][$tag] export bytes=${bytes.lengthInBytes}');
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
