// image_editor/lib/controller/text_layer_manager.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/editor_models.dart';

/// 文本图层管理器
/// 负责管理所有文本图层的增删改查
class TextLayerManager {
  // 使用 Map 优化查找性能，O(1) 复杂度
  final Map<String, TextLayerData> _layers = {};
  String? _selectedLayerId;

  /// 获取所有文本图层列表（按添加顺序）
  List<TextLayerData> get layers => _layers.values.toList();

  /// 获取当前选中的图层ID
  String? get selectedLayerId => _selectedLayerId;

  /// 获取选中的图层
  TextLayerData? get selectedLayer => _selectedLayerId != null ? _layers[_selectedLayerId] : null;

  /// 添加文本图层
  String addLayer({
    required String text,
    required Offset position,
    Color color = Colors.blue,
    double fontSize = 32.0,
  }) {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final layer = TextLayerData(
      id: id,
      text: text,
      position: position,
      color: color,
      fontSize: fontSize,
    );
    _layers[id] = layer;
    return id;
  }

  /// 删除指定的文本图层
  bool removeLayer(String id) {
    if (_layers.containsKey(id)) {
      _layers.remove(id);
      if (_selectedLayerId == id) {
        _selectedLayerId = null;
      }
      return true;
    }
    return false;
  }

  /// 删除当前选中的图层
  bool removeSelectedLayer() {
    if (_selectedLayerId != null) {
      return removeLayer(_selectedLayerId!);
    }
    return false;
  }

  /// 选择文本图层
  bool selectLayer(String id) {
    if (_layers.containsKey(id)) {
      _selectedLayerId = id;
      return true;
    }
    return false;
  }

  /// 根据点击位置选择文本图层
  String? selectLayerAt(Offset tapPosition, Size canvasSize) {
    // 从最上层的图层开始检查（按添加顺序的逆序）
    final layersList = _layers.values.toList().reversed;
    for (final layer in layersList) {
      final bounds = _getTextLayerBounds(layer, canvasSize);
      if (bounds.contains(tapPosition)) {
        _selectedLayerId = layer.id;
        return layer.id;
      }
    }
    return null;
  }

  /// 清除选择
  void clearSelection() {
    _selectedLayerId = null;
  }

  /// 更新选中图层的颜色
  bool updateSelectedLayerColor(Color color) {
    if (_selectedLayerId != null && _layers.containsKey(_selectedLayerId)) {
      _layers[_selectedLayerId]!.color = color;
      return true;
    }
    return false;
  }

  /// 更新选中图层的大小
  bool updateSelectedLayerSize(double size) {
    if (_selectedLayerId != null && _layers.containsKey(_selectedLayerId)) {
      _layers[_selectedLayerId]!.fontSize = size;
      return true;
    }
    return false;
  }

  /// 更新选中图层的位置
  bool updateSelectedLayerPosition(Offset position) {
    if (_selectedLayerId != null && _layers.containsKey(_selectedLayerId)) {
      _layers[_selectedLayerId]!.position = position;
      return true;
    }
    return false;
  }

  /// 获取文本图层的边界框
  Rect _getTextLayerBounds(TextLayerData layer, Size canvasSize) {
    final paragraph = _buildParagraph(layer);
    paragraph.layout(ui.ParagraphConstraints(width: canvasSize.width));

    // 增加一些触摸区域，方便用户点击
    const padding = 16.0;
    return Rect.fromCenter(
      center: layer.position,
      width: paragraph.width + padding,
      height: paragraph.height + padding,
    );
  }

  /// 构建段落
  ui.Paragraph _buildParagraph(TextLayerData layer) {
    final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.center);
    final textStyle = ui.TextStyle(color: layer.color, fontSize: layer.fontSize);
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(layer.text);
    return paragraphBuilder.build();
  }

  /// 深拷贝所有图层（用于历史记录）
  List<TextLayerData> copyLayers() {
    return _layers.values.map((layer) {
      return TextLayerData(
        id: layer.id,
        text: layer.text,
        position: layer.position,
        color: layer.color,
        fontSize: layer.fontSize,
        isSelected: layer.isSelected,
      );
    }).toList();
  }

  /// 恢复图层（用于历史记录）
  void restoreLayers(List<TextLayerData> layers) {
    _layers.clear();
    for (final layer in layers) {
      _layers[layer.id] = TextLayerData(
        id: layer.id,
        text: layer.text,
        position: layer.position,
        color: layer.color,
        fontSize: layer.fontSize,
        isSelected: layer.isSelected,
      );
    }
    _selectedLayerId = null;
  }

  /// 清空所有图层
  void clear() {
    _layers.clear();
    _selectedLayerId = null;
  }

  /// 获取图层数量
  int get count => _layers.length;

  /// 检查是否有图层
  bool get isEmpty => _layers.isEmpty;

  /// 检查是否有选中的图层
  bool get hasSelection => _selectedLayerId != null;
}

