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

  // [BUG FIX] 1. 添加一个状态锁，防止动画重入
  bool _isSnapping = false;

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
    // [BUG FIX] 2. 如果正在执行吸附动画，则不处理滚动事件，防止用户输入干扰动画
    if (_isSnapping || _centerOffset == 0) return;
    final newDegrees = _offsetToAngle(_scrollController.offset);
    // 避免不必要的回调和重绘
    if ((newDegrees - _currentDegrees).abs() > 0.01) {
      // 使用 addPostFrameCallback 确保在 build 周期之外更新状态，更安全
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentDegrees = newDegrees;
          });
        }
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

  // [BUG FIX] 3. 重写整个通知处理逻辑，使用状态锁
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      // 如果当前正在执行吸附动画，或者用户只是点击而没有滚动，则忽略
      if (_isSnapping || notification.metrics.extentBefore == 0 && notification.metrics.extentAfter == 0) {
        return true;
      }

      final targetDegrees = _currentDegrees.roundToDouble();
      double finalDegrees = _currentDegrees;

      if ((_currentDegrees).abs() < 0.5) {
        finalDegrees = 0.0;
        HapticFeedback.lightImpact();
      } else {
        finalDegrees = targetDegrees;
      }

      final targetOffset = _angleToOffset(finalDegrees);

      // 如果已经在目标位置，则无需动画，但要确保状态正确
      if ((_scrollController.offset - targetOffset).abs() < 0.1) {
        if (_currentDegrees != finalDegrees) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() { _currentDegrees = finalDegrees; });
              widget.onAngleChanged(finalDegrees);
            }
          });
        }
        return true;
      }

      // *** 核心修复逻辑 ***
      // 在动画开始前，设置锁
      setState(() {
        _isSnapping = true;
      });
      // 执行动画
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).whenComplete(() {
        // 动画完成后（无论成功、失败或被取消），释放锁
        if (mounted) {
          setState(() {
            _currentDegrees = finalDegrees;
            _isSnapping = false;
          });
          // 确保最终角度被回调
          widget.onAngleChanged(finalDegrees);
        }
      });
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
            if(_currentDegrees != 0.0)
              _buildResetText()
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeText() {
    return Positioned(
      top: 0,
      child: Row(
        children: [
          Text(
            '${_currentDegrees == 0.0 ? '0.0' : _currentDegrees.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      )
    );
  }

  Widget _buildResetText(){
    return Positioned(
      top: -8,
      right: 0,
      child:
      TextButton(
        onPressed: () {
          setState(() {
            _currentDegrees = 0.0;
          });
          widget.onAngleChanged(0.0);
        },
        child: Text("重置", style: TextStyle(fontSize: 12 , color: Colors.grey[400]) ,)
      )
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


/// Bug 分析
/// 问题出在 FreeRotateSlider 的 _onScrollNotification 方法中，它与 animateTo 方法之间形成了一个致命的闭环。
// 让我们来追踪一下卡死的场景：用户手动将滑块拖动到精确的 0.0° 位置后松手。
// 用户松手：ScrollEndNotification 被触发。
// 进入 _onScrollNotification：
// _currentDegrees 此时已经是 0.0。
// 代码计算出 finalDegrees 也是 0.0。
// 代码计算出 targetOffset，这个值正是当前 _scrollController.offset 的值。
// 调用 animateTo：调用了 _scrollController.animateTo(targetOffset, ...)。你让控制器“动画”到它已经所在的完全相同的位置。
// 致命循环：
// 在某些 Flutter 版本或特定条件下，当 animateTo 的目标和当前位置相同时，它可能会立即“完成”动画。
// 这个“完成”行为会再次触发一个 ScrollEndNotification！
// 于是，代码再次进入 _onScrollNotification，再次计算出相同的 targetOffset，再次调用 animateTo 到相同的位置，然后再次触发 ScrollEndNotification...
// 这个过程以极高的速度重复，形成了一个无限循环，瞬间占满了 CPU 资源，导致应用彻底卡死。
// 这个 Bug 的触发条件很苛刻（必须精确地在目标位置松手），但一旦触发就是灾难性的。
// 解决 状态锁：在开始动画时设置一个“正在动画中”的锁，动画完成前忽略所有后续的 ScrollEndNotification。这是更健壮、更推荐的方案。