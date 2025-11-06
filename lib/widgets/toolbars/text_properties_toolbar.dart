// image_editor/lib/widgets/toolbars/text_properties_toolbar.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';

class TextPropertiesToolbar extends StatelessWidget {
  final ImageEditorController controller;
  const TextPropertiesToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if(controller.selectedTextLayerId == null){
      return const SizedBox.shrink();
    }
    final selectedLayer = controller.textLayers.firstWhere(
          (l) => l.id == controller.selectedTextLayerId,
      orElse: () => throw 'No layer selected!', //理论上不应该发生
    );
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10),
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 颜色选择器
          _buildColorPicker(),
          // 字体大小滑块
          _buildSizeSlider(selectedLayer.fontSize),
          // 删除按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                controller.deleteSelectedTextLayer();
              },
              tooltip: '删除文本',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    const List<Color> colors = [
      Colors.white, Colors.black, Colors.red, Colors.orange,
      Colors.yellow, Colors.green, Colors.blue, Colors.purple,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: colors.map((color) {
            return GestureDetector(
              onTap: () => controller.updateSelectedTextColor(color),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSizeSlider(double currentSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Icon(Icons.format_size, color: Colors.white),
          Expanded(
            child: Slider(
              value: currentSize,
              min: 12.0,
              max: 100.0,
              activeColor: Colors.orange,
              inactiveColor: Colors.grey,
              onChanged: (value) {
                controller.updateSelectedTextSize(value);
              },
            ),
          ),
          Text(
            currentSize.toInt().toString(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          )
        ],
      ),
    );
  }
}
