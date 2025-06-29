import 'package:flutter/material.dart';
import 'dart:math' as math;

class MinimalWaveform extends StatefulWidget {
  final List<double> waveformData;
  final double height;
  final bool isActive;
  final Color primaryColor;

  const MinimalWaveform({
    super.key,
    required this.waveformData,
    this.height = 120,
    this.isActive = true,
    this.primaryColor = Colors.red,
  });

  @override
  State<MinimalWaveform> createState() => _MinimalWaveformState();
}

class _MinimalWaveformState extends State<MinimalWaveform>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 波形动画控制器
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));
    
    if (widget.isActive) {
      _pulseController.repeat();
      _waveController.forward();
    }
  }

  @override
  void didUpdateWidget(MinimalWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat();
      _waveController.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _waveController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _MinimalWaveformPainter(
              waveformData: widget.waveformData,
              primaryColor: widget.primaryColor,
              pulseValue: _pulseAnimation.value,
              waveValue: _waveAnimation.value,
              isActive: widget.isActive,
            ),
          ),
        );
      },
    );
  }
}

class _MinimalWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color primaryColor;
  final double pulseValue;
  final double waveValue;
  final bool isActive;

  _MinimalWaveformPainter({
    required this.waveformData,
    required this.primaryColor,
    required this.pulseValue,
    required this.waveValue,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final barCount = 60; // 固定条数，更密集
    final barWidth = size.width / barCount;
    final barSpacing = barWidth * 0.3;
    final actualBarWidth = barWidth - barSpacing;
    
    // 绘制中心圆圈
    _drawCenterCircle(canvas, size, centerY);
    
    // 绘制波形条
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barSpacing / 2;
      
      // 获取数据值，如果数据不足则使用默认值
      final dataIndex = (i * waveformData.length / barCount).floor();
      final amplitude = dataIndex < waveformData.length 
          ? waveformData[dataIndex] 
          : 0.1;
      
      // 计算条形高度
      final maxHeight = size.height * 0.8;
      final minHeight = 4.0;
      var barHeight = minHeight + (maxHeight - minHeight) * amplitude * waveValue;
      
      // 添加脉冲效果
      if (isActive) {
        final distance = (i - barCount / 2).abs() / (barCount / 2);
        final pulseEffect = math.sin(pulseValue * math.pi * 2 - distance * math.pi) * 0.3;
        barHeight *= (1 + pulseEffect.clamp(0.0, 1.0));
      }
      
      // 计算颜色和透明度
      final distanceFromCenter = (i - barCount / 2).abs() / (barCount / 2);
      final opacity = isActive 
          ? (1.0 - distanceFromCenter * 0.5).clamp(0.3, 1.0)
          : 0.3;
      
      final paint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      
      // 绘制圆角矩形
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          centerY - barHeight / 2,
          actualBarWidth,
          barHeight,
        ),
        Radius.circular(actualBarWidth / 2),
      );
      
      canvas.drawRRect(rect, paint);
    }
  }
  
  void _drawCenterCircle(Canvas canvas, Size size, double centerY) {
    if (!isActive) return;
    
    // 外圈脉冲
    final outerRadius = 20.0 + pulseValue * 10;
    final outerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1 + pulseValue * 0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      outerRadius,
      outerPaint,
    );
    
    // 内圈
    final innerRadius = 8.0;
    final innerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      innerRadius,
      innerPaint,
    );
    
    // 中心点
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, centerY),
      3,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(_MinimalWaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.waveValue != waveValue ||
           oldDelegate.isActive != isActive;
  }
}

// 简约的圆形声波动画
class CircularSoundWave extends StatefulWidget {
  final double size;
  final bool isActive;
  final Color color;
  final double amplitude;

  const CircularSoundWave({
    super.key,
    this.size = 200,
    this.isActive = true,
    this.color = Colors.red,
    this.amplitude = 0.5,
  });

  @override
  State<CircularSoundWave> createState() => _CircularSoundWaveState();
}

class _CircularSoundWaveState extends State<CircularSoundWave>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularSoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CircularWavePainter(
              color: widget.color,
              progress: _animation.value,
              amplitude: widget.amplitude,
              isActive: widget.isActive,
            ),
          ),
        );
      },
    );
  }
}

class _CircularWavePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double amplitude;
  final bool isActive;

  _CircularWavePainter({
    required this.color,
    required this.progress,
    required this.amplitude,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // 绘制多个波纹
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final radius = maxRadius * 0.3 + maxRadius * 0.6 * waveProgress;
      final opacity = isActive 
          ? (1.0 - waveProgress) * 0.3 * amplitude
          : 0.1;
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius, paint);
    }
    
    // 绘制中心圆
    final centerPaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.8 : 0.4)
      ..style = PaintingStyle.fill;
    
    final centerRadius = maxRadius * 0.25 * (1 + amplitude * 0.2);
    canvas.drawCircle(center, centerRadius, centerPaint);
    
    // 绘制内部图标区域
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final iconRadius = centerRadius * 0.6;
    canvas.drawCircle(center, iconRadius, iconPaint);
  }

  @override
  bool shouldRepaint(_CircularWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.isActive != isActive;
  }
}