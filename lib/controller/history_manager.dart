// image_editor/lib/controller/history_manager.dart

import 'dart:ui' as ui;
import '../models/editor_models.dart';

/// 状态快照数据结构（用于历史记录）
class EditorStateSnapshot {
  final ui.Image image;
  final List<TextLayerData> textLayers;
  final double rotationAngle;
  final double scale;

  EditorStateSnapshot({
    required this.image,
    required this.textLayers,
    required this.rotationAngle,
    required this.scale,
  });
}

/// 历史记录管理器
/// 负责管理编辑历史，支持撤销和回退功能
class HistoryManager {
  final List<EditorStateSnapshot> _snapshots = [];
  static const int maxHistorySize = 10;

  /// 保存当前状态到历史快照
  void saveSnapshot({
    required ui.Image image,
    required List<TextLayerData> textLayers,
    required double rotationAngle,
    required double scale,
  }) {
    // 深拷贝文本图层列表
    final copiedTextLayers = textLayers.map((layer) {
      return TextLayerData(
        id: layer.id,
        text: layer.text,
        position: layer.position,
        color: layer.color,
        fontSize: layer.fontSize,
        isSelected: layer.isSelected,
      );
    }).toList();

    final snapshot = EditorStateSnapshot(
      image: image, // ui.Image 是不可变的，可以直接引用
      textLayers: copiedTextLayers,
      rotationAngle: rotationAngle,
      scale: scale,
    );

    _snapshots.add(snapshot);

    // 限制历史记录数量，避免内存占用过大
    if (_snapshots.length > maxHistorySize) {
      _snapshots.removeAt(0);
    }
  }

  /// 检查是否可以回退（是否有历史记录）
  bool get canUndo => _snapshots.isNotEmpty;

  /// 获取最后一个快照并移除
  EditorStateSnapshot? popSnapshot() {
    if (_snapshots.isEmpty) return null;
    return _snapshots.removeLast();
  }

  /// 清空所有历史记录
  void clear() {
    _snapshots.clear();
  }

  /// 获取历史记录数量
  int get count => _snapshots.length;
}

