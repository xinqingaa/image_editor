// image_editor/lib/widgets/toolbars/crop_toolbar.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';

class CropToolbar extends StatelessWidget {
  final ImageEditorController controller;

  const CropToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _CropOption(
        tool: EditToolsMenu.cropFree,
        icon: Icons.crop_free,
        aspectRatio: null,
      ),
      _CropOption(
        tool: EditToolsMenu.crop16_9,
        icon: Icons.crop_16_9,
        aspectRatio: 16 / 9,
      ),
      _CropOption(
        tool: EditToolsMenu.crop5_4,
        icon: Icons.crop_5_4,
        aspectRatio: 5 / 4,
      ),
      _CropOption(
        tool: EditToolsMenu.crop1_1,
        icon: Icons.crop_square,
        aspectRatio: 1 / 1,
      ),
    ].where((option) => controller.isToolEnabled(option.tool)).toList();

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttons
                  .map(
                    (option) => _buildCropButton(
                      tool: option.tool,
                      icon: option.icon,
                      aspectRatio: option.aspectRatio,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildCropButton({required EditToolsMenu tool, required IconData icon, required double? aspectRatio}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: controller.activeTool == tool ? Colors.grey[800] : Colors.transparent,
        ),
        onPressed: () => controller.selectCropTool(tool, aspectRatio: aspectRatio),
      ),
    );
  }
}

class _CropOption {
  final EditToolsMenu tool;
  final IconData icon;
  final double? aspectRatio;

  const _CropOption({
    required this.tool,
    required this.icon,
    required this.aspectRatio,
  });
}
