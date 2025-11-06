import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor.dart';
import 'dart:ui' as ui;
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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

Future<ui.Image> loadImageFromAssets(String path) async {
  ByteData data = await rootBundle.load(path);
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

class _MyHomePageState extends State<MyHomePage> {
  // 用于存储编辑后的图片数据
  ui.Image? _editedImage;
  ui.Image? _originalImage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor '),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildImageDisplay(),
              const SizedBox(height: 24),
              ElevatedButton(
                // 如果原始图片还未加载，则禁用按钮
                onPressed: () async {
                  // 1. 加载图片
                  final ui.Image originalImage =
                      await loadImageFromAssets('assets/sample.jpg');
                  setState(() {
                    _originalImage = originalImage;
                  });
                  print('originalImage: $originalImage');
                  // 2. 导航到编辑器页面，并等待返回结果
                  final ui.Image? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageEditor(image: originalImage),
                    ),
                  );
                  print('result: $result');

                  if (result != null) {
                    setState(() {
                      _editedImage = result;
                    });
                  }
                },
                child: const Text('打开编辑器'),
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            _originalImage != null
                ? '原始图片: ${_originalImage!.width}x${_originalImage!.height}'
                : '原始图片:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_originalImage != null)
            _buildImage(_originalImage!),

          Text(
            _editedImage != null
                ? '编辑后的图片: ${_editedImage!.width}x${_editedImage!.height}'
                : '编辑后的图片:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_editedImage != null)
            _buildImage(_editedImage!),
        ],
      ),
    );
  }

  Widget _buildImage(ui.Image image) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RawImage(image: image, fit: BoxFit.contain),
    );
  }
}
