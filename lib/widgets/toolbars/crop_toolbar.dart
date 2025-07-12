// image_editor/lib/widgets/toolbars/crop_toolbar.dart

import 'package:flutter/material.dart';
import '../../controller/image_editor_controller.dart';
import '../../models/editor_models.dart';

class CropToolbar extends StatelessWidget {
  final ImageEditorController controller;

  const CropToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCropButton(
                  tool: EditToolsMenu.cropFree,
                  icon: Icons.crop_free,
                  aspectRatio: null,
                ),
                _buildCropButton(
                  tool: EditToolsMenu.crop16_9,
                  icon: Icons.crop_16_9,
                  aspectRatio: 16 / 9,
                ),
                _buildCropButton(
                  tool: EditToolsMenu.crop5_4,
                  icon: Icons.crop_5_4,
                  aspectRatio: 5 / 4,
                ),
                _buildCropButton(
                  tool: EditToolsMenu.crop1_1,
                  icon: Icons.crop_square,
                  aspectRatio: 1 / 1,
                ),

              ],
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
