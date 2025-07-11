// image_editor/lib/widgets/toolbars/free_rotate_slider.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个自定义的、带刻度的水平滑动条，用于自由旋转。
class FreeRotateSlider extends StatefulWidget {
  /// 旋转角度改变时的回调，返回单位为度(degrees)。
  final ValueChanged<double> onAngleChanged;

  /// 初始角度，单位为度(degrees)。
  final double initialAngle;

  const FreeRotateSlider({
    super.key,
    required this.onAngleChanged,
    this.initialAngle = 0.0,
  });

  @override
  State<FreeRotateSlider> createState() => _FreeRotateSliderState();
}

class _FreeRotateSliderState extends State<FreeRotateSlider> {
  late final ScrollController _scrollController;

  // 定义刻度尺的参数
  final double _degreesRange = 90.0; // 总范围: -45° 到 +45°
  final int _totalTicks = 90; // 总刻度数
  final double _pixelsPerTick = 6.0; // 每个刻度之间的像素距离

  double _totalWidth = 0;
  double _centerOffset = 0;
  double _currentDegrees = 0.0;

  @override
  void initState() {
    super.initState();
    _currentDegrees = widget.initialAngle;
    _totalWidth = _totalTicks * _pixelsPerTick;

    // 计算初始滚动位置
    final initialOffset = _angleToOffset(_currentDegrees);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    // 监听滚动来更新角度
    _scrollController.addListener(_onScroll);

    // 在第一帧渲染后获取真实的中心点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _centerOffset = context.size!.width / 2;
        });
        // 再次确保滚动位置正确
        _scrollController.jumpTo(_angleToOffset(_currentDegrees));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_centerOffset == 0) return;

    final newDegrees = _offsetToAngle(_scrollController.offset);

    // 避免不必要的回调和重绘
    if ((newDegrees - _currentDegrees).abs() > 0.01) {
      setState(() {
        _currentDegrees = newDegrees;
      });
      widget.onAngleChanged(_currentDegrees);
    }
  }

  /// 将角度转换为滚动偏移量
  double _angleToOffset(double angle) {
    final pixelsPerDegree = _totalWidth / _degreesRange;
    return (angle + _degreesRange / 2) * pixelsPerDegree;
  }

  /// 将滚动偏移量转换为角度
  double _offsetToAngle(double offset) {
    final pixelsPerDegree = _totalWidth / _degreesRange;
    final angle = (offset / pixelsPerDegree) - (_degreesRange / 2);
    // 将角度限制在范围内
    return angle.clamp(-_degreesRange / 2, _degreesRange / 2);
  }

  /// 在滚动结束时，吸附到最近的整数度或0度
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final targetDegrees = _currentDegrees.roundToDouble();
      double finalDegrees = _currentDegrees;

      // 如果非常接近0度，则强力吸附到0
      if ((_currentDegrees).abs() < 0.5) {
        finalDegrees = 0.0;
        HapticFeedback.lightImpact(); // 轻微震动反馈
      } else {
        finalDegrees = targetDegrees;
      }

      final targetOffset = _angleToOffset(finalDegrees);
      // 使用动画滚动到目标位置
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: SizedBox(
        height: 80, // 给组件一个固定的高度
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 刻度尺本体
            _buildRuler(),
            // 中心指针
            _buildPointer(),
            // 角度显示
            _buildDegreeText(),
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeText() {
    return Positioned(
      top: 0,
      child: Text(
        '${_currentDegrees.toStringAsFixed(1)}°',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPointer() {
    return Container(
      width: 2,
      height: 25,
      color: Colors.orange,
    );
  }

  Widget _buildRuler() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 在LayoutBuilder中更新中心点，更可靠
        _centerOffset = constraints.maxWidth / 2;

        return ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: _totalTicks + 2, // +2 用于前后的空白
          itemBuilder: (context, index) {
            // 开头和结尾的空白，确保刻度尺能滚动到中心
            if (index == 0 || index == _totalTicks + 1) {
              return SizedBox(width: _centerOffset);
            }

            final tickIndex = index - 1;
            final isMajorTick = tickIndex % 10 == 5; // 每5度一个长刻度
            final isNormalTick = tickIndex % 5 == 0; // 每1度一个中刻度

            return Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.only(right: _pixelsPerTick - 1),
                width: 1,
                height: isMajorTick ? 20 : (isNormalTick ? 12 : 6),
                color: Colors.grey[600],
              ),
            );
          },
        );
      },
    );
  }
}
