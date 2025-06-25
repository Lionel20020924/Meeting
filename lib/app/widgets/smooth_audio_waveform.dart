import 'package:flutter/material.dart';
import 'dart:math' as math;

class SmoothAudioWaveform extends StatefulWidget {
  final List<double> waveformData;
  final double height;
  final Color color;
  final bool isActive;

  const SmoothAudioWaveform({
    super.key,
    required this.waveformData,
    this.height = 100,
    required this.color,
    this.isActive = true,
  });

  @override
  State<SmoothAudioWaveform> createState() => _SmoothAudioWaveformState();
}

class _SmoothAudioWaveformState extends State<SmoothAudioWaveform>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<double> _previousData = [];
  List<double> _targetData = [];
  List<double> _currentData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animation.addListener(() {
      setState(() {
        _updateCurrentData();
      });
    });
    _currentData = List.filled(widget.waveformData.length, 0.0);
  }

  @override
  void didUpdateWidget(SmoothAudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waveformData != oldWidget.waveformData) {
      _previousData = List.from(_currentData);
      _targetData = List.from(widget.waveformData);
      _animationController.forward(from: 0);
    }
  }

  void _updateCurrentData() {
    if (_previousData.isEmpty || _targetData.isEmpty) return;
    
    _currentData = List.generate(
      math.min(_previousData.length, _targetData.length),
      (index) {
        final prev = index < _previousData.length ? _previousData[index] : 0.0;
        final target = index < _targetData.length ? _targetData[index] : 0.0;
        return prev + (target - prev) * _animation.value;
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: SmoothWaveformPainter(
          waveformData: _currentData.isNotEmpty ? _currentData : widget.waveformData,
          color: widget.color,
          isActive: widget.isActive,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class SmoothWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final bool isActive;

  SmoothWaveformPainter({
    required this.waveformData,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Draw bars with smooth height transitions
    final barCount = waveformData.length;
    final totalBarWidth = width * 0.7; // 70% for bars
    final barWidth = totalBarWidth / barCount;
    final spacing = (width - totalBarWidth) / (barCount + 1);

    for (int i = 0; i < barCount; i++) {
      final x = spacing + i * (barWidth + spacing / barCount) + barWidth / 2;
      final amplitude = waveformData[i];
      
      // Minimum bar height for visual appeal
      final minHeight = 3.0;
      final maxHeight = height * 0.9;
      final barHeight = minHeight + (maxHeight - minHeight) * amplitude;
      
      // Calculate bar position
      final barTop = centerY - barHeight / 2;
      
      // Draw bar with gradient
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth * 0.4, barTop, barWidth * 0.8, barHeight),
        Radius.circular(barWidth * 0.4),
      );
      
      // Create gradient paint
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isActive ? 0.6 + 0.4 * amplitude : 0.3),
            color.withValues(alpha: isActive ? 0.3 + 0.3 * amplitude : 0.2),
          ],
        ).createShader(rect.outerRect);
      
      canvas.drawRRect(rect, gradientPaint);
      
      // Add subtle glow for active high amplitude
      if (amplitude > 0.6 && isActive) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.1 * amplitude)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 4 * amplitude);
        
        canvas.drawRRect(rect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SmoothWaveformPainter oldDelegate) {
    return waveformData != oldDelegate.waveformData ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive;
  }
}

// Alternative flowing waveform visualization
class FlowingWaveform extends StatefulWidget {
  final List<double> waveformData;
  final double height;
  final Color color;
  final bool isActive;

  const FlowingWaveform({
    super.key,
    required this.waveformData,
    this.height = 100,
    required this.color,
    this.isActive = true,
  });

  @override
  State<FlowingWaveform> createState() => _FlowingWaveformState();
}

class _FlowingWaveformState extends State<FlowingWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _phaseController;
  
  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (widget.isActive) {
      _phaseController.repeat();
    }
  }

  @override
  void didUpdateWidget(FlowingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _phaseController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _phaseController.stop();
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phaseController,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: FlowingWaveformPainter(
              waveformData: widget.waveformData,
              color: widget.color,
              isActive: widget.isActive,
              phase: _phaseController.value * 2 * math.pi,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class FlowingWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final bool isActive;
  final double phase;

  FlowingWaveformPainter({
    required this.waveformData,
    required this.color,
    required this.isActive,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Create smooth flowing wave path
    final path = Path();
    final fillPath = Path();
    
    // Start from left edge
    path.moveTo(0, centerY);
    fillPath.moveTo(0, centerY);
    
    // Create smooth wave using bezier curves
    for (int i = 0; i < waveformData.length; i++) {
      final x = (i / (waveformData.length - 1)) * width;
      final amplitude = waveformData[i];
      
      // Add flowing motion
      final flowOffset = math.sin(phase + (i / waveformData.length) * math.pi * 2) * 0.2;
      final adjustedAmplitude = math.max(0, math.min(1, amplitude + flowOffset * amplitude));
      
      // Calculate wave height with smooth interpolation
      final waveHeight = height * 0.4 * adjustedAmplitude;
      
      if (i == 0) {
        path.lineTo(x, centerY - waveHeight);
        fillPath.lineTo(x, centerY - waveHeight);
      } else {
        // Use cubic bezier for ultra-smooth curves
        final prevX = ((i - 1) / (waveformData.length - 1)) * width;
        final prevAmplitude = i > 0 ? waveformData[i - 1] : 0;
        final prevFlowOffset = math.sin(phase + ((i - 1) / waveformData.length) * math.pi * 2) * 0.2;
        final prevAdjustedAmplitude = math.max(0, math.min(1, prevAmplitude + prevFlowOffset * prevAmplitude));
        final prevWaveHeight = height * 0.4 * prevAdjustedAmplitude;
        
        final cp1x = prevX + (x - prevX) * 0.5;
        final cp1y = centerY - prevWaveHeight;
        final cp2x = prevX + (x - prevX) * 0.5;
        final cp2y = centerY - waveHeight;
        
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, centerY - waveHeight);
        fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, x, centerY - waveHeight);
      }
    }
    
    // Mirror for lower wave
    for (int i = waveformData.length - 1; i >= 0; i--) {
      final x = (i / (waveformData.length - 1)) * width;
      final amplitude = waveformData[i];
      final flowOffset = math.sin(phase + (i / waveformData.length) * math.pi * 2) * 0.2;
      final adjustedAmplitude = math.max(0, math.min(1, amplitude + flowOffset * amplitude));
      final waveHeight = height * 0.4 * adjustedAmplitude;
      
      fillPath.lineTo(x, centerY + waveHeight);
    }
    
    fillPath.close();
    
    // Draw gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: isActive ? 0.3 : 0.1),
          color.withValues(alpha: isActive ? 0.1 : 0.05),
          color.withValues(alpha: isActive ? 0.1 : 0.05),
          color.withValues(alpha: isActive ? 0.3 : 0.1),
        ],
        stops: const [0.0, 0.48, 0.52, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw stroke for upper wave
    final strokePaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(path, strokePaint);
    
    // Draw mirrored stroke for lower wave
    final lowerPath = Path();
    lowerPath.moveTo(0, centerY);
    
    for (int i = 0; i < waveformData.length; i++) {
      final x = (i / (waveformData.length - 1)) * width;
      final amplitude = waveformData[i];
      final flowOffset = math.sin(phase + (i / waveformData.length) * math.pi * 2) * 0.2;
      final adjustedAmplitude = math.max(0, math.min(1, amplitude + flowOffset * amplitude));
      final waveHeight = height * 0.4 * adjustedAmplitude;
      
      if (i == 0) {
        lowerPath.lineTo(x, centerY + waveHeight);
      } else {
        final prevX = ((i - 1) / (waveformData.length - 1)) * width;
        final prevAmplitude = i > 0 ? waveformData[i - 1] : 0;
        final prevFlowOffset = math.sin(phase + ((i - 1) / waveformData.length) * math.pi * 2) * 0.2;
        final prevAdjustedAmplitude = math.max(0, math.min(1, prevAmplitude + prevFlowOffset * prevAmplitude));
        final prevWaveHeight = height * 0.4 * prevAdjustedAmplitude;
        
        final cp1x = prevX + (x - prevX) * 0.5;
        final cp1y = centerY + prevWaveHeight;
        final cp2x = prevX + (x - prevX) * 0.5;
        final cp2y = centerY + waveHeight;
        
        lowerPath.cubicTo(cp1x, cp1y, cp2x, cp2y, x, centerY + waveHeight);
      }
    }
    
    canvas.drawPath(lowerPath, strokePaint);
  }

  @override
  bool shouldRepaint(FlowingWaveformPainter oldDelegate) {
    return waveformData != oldDelegate.waveformData ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive ||
           phase != oldDelegate.phase;
  }
}