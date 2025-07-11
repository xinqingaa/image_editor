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
      body: Center(
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
                  final ui.Image? imageToEdit = await loadImageFromAssets('assets/sample.jpg');

                  if (imageToEdit == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("图片加载失败")));
                    return;
                  }

                  // 2. 导航到编辑器页面，并等待返回结果
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageEditor(image: imageToEdit),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _editedImage = result;
                    });
                  }
                },
                child: const Text('编辑器'),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // 一个小组件，用于优雅地展示图片
  Widget _buildImageDisplay() {
    return Column(
      children: [
        const Text(
          '编辑后的图片:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _editedImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: RawImage(
                image:  _editedImage!,
                fit: BoxFit.contain
            ),
          )
              : const Padding(
            padding: EdgeInsets.all(48.0),
            child: Text('点击 "打开编辑器" 开始编辑'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
