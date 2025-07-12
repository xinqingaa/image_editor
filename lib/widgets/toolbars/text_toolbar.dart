import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';

class TextToolbar extends StatefulWidget {
  final ImageEditorController controller;
  const TextToolbar({super.key, required this.controller});

  @override
  State<TextToolbar> createState() => _TextToolbarState();
}

class _TextToolbarState extends State<TextToolbar> {
  final GlobalKey<CustomInputState> inputKey = GlobalKey<CustomInputState>();


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(bottom: 6),
      child: CustomInput(
        key: inputKey,
        hintText: "输入文字...",
        onChanged: (String value){
          widget.controller.updateEditingText(value);
        }
      )
    );
  }
}


class CustomInput extends StatefulWidget {
  final Function(String) onChanged;
  // 将 initValue 改为 hintText，意图更明确
  final String? hintText;
  const CustomInput({super.key, required this.onChanged, this.hintText});

  @override
  State<CustomInput> createState() => CustomInputState();
}

class CustomInputState extends State<CustomInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  // 提供一个方法给外部，用于清空文本
  void clear() {
    _controller.clear();
  }

  // 提供一个方法给外部，用于取消焦点
  void unfocus() {
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(fontSize: 14, color: Colors.white), // 调整文字样式
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.text,
      cursorColor: Colors.orange, // 换个显眼的颜色
      // 移除 autofocus
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        // 使用 hintText 作为占位符
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder( // 使用OutlineInputBorder效果更好
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none, // 无边框
        ),
      ),
    );
  }
}