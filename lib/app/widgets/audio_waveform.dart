import 'package:flutter/material.dart';

class AudioWaveform extends StatelessWidget {
  final List<double> waveformData;
  final double height;
  final Color color;
  final double strokeWidth;
  final bool isActive;

  const AudioWaveform({
    super.key,
    required this.waveformData,
    this.height = 60,
    this.color = Colors.white,
    this.strokeWidth = 3.0,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: WaveformPainter(
          waveformData: waveformData,
          color: color,
          strokeWidth: strokeWidth,
          isActive: isActive,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final double strokeWidth;
  final bool isActive;

  WaveformPainter({
    required this.waveformData,
    required this.color,
    required this.strokeWidth,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    // Calculate bar width and spacing
    final barCount = waveformData.length;
    final totalSpacing = width * 0.3; // 30% of width for spacing
    final barSpacing = totalSpacing / (barCount - 1);
    final barWidth = (width - totalSpacing) / barCount;
    
    // Draw waveform as bars
    for (int i = 0; i < waveformData.length; i++) {
      final x = i * (barWidth + barSpacing) + barWidth / 2;
      final amplitude = waveformData[i];
      
      // Minimum bar height for visual appeal
      final minHeight = 4.0;
      final maxHeight = height * 0.8;
      final barHeight = minHeight + (maxHeight - minHeight) * amplitude;
      
      // Draw vertical bar
      final barTop = centerY - barHeight / 2;
      
      // Create rounded rectangle for each bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, barTop, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      
      // Use filled style for bars
      final barPaint = Paint()
        ..color = isActive 
            ? color.withValues(alpha: 0.3 + 0.7 * amplitude) // Dynamic opacity based on amplitude
            : color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(rect, barPaint);
      
      // Add glow effect for high amplitude bars
      if (amplitude > 0.5 && isActive) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.2 * amplitude)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
        canvas.drawRRect(rect, glowPaint);
      }
    }
    
    // Draw center line
    final centerLinePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(0, centerY),
      Offset(width, centerY),
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return waveformData != oldDelegate.waveformData ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive;
  }
}

// Alternative smooth waveform style
class SmoothWaveform extends StatelessWidget {
  final List<double> waveformData;
  final double height;
  final Color color;
  final double strokeWidth;
  final bool isActive;

  const SmoothWaveform({
    super.key,
    required this.waveformData,
    this.height = 60,
    this.color = Colors.white,
    this.strokeWidth = 3.0,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: SmoothWaveformPainter(
          waveformData: waveformData,
          color: color,
          strokeWidth: strokeWidth,
          isActive: isActive,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class SmoothWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final double strokeWidth;
  final bool isActive;

  SmoothWaveformPainter({
    required this.waveformData,
    required this.color,
    required this.strokeWidth,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = isActive ? color : color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = isActive 
          ? color.withValues(alpha: 0.1)
          : color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    // Create smooth waveform path
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < waveformData.length; i++) {
      final x = (i / (waveformData.length - 1)) * width;
      
      // Apply smoothing
      final smoothedAmplitude = _applySmoothingWindow(waveformData, i);
      
      // Calculate y positions for upper and lower bounds
      final waveHeight = height * 0.4 * smoothedAmplitude;
      final upperY = centerY - waveHeight;
      final lowerY = centerY + waveHeight;
      
      if (i == 0) {
        path.moveTo(x, centerY);
        fillPath.moveTo(x, upperY);
      } else {
        // Use quadratic bezier curves for smooth transitions
        final prevX = ((i - 1) / (waveformData.length - 1)) * width;
        final controlX = (prevX + x) / 2;
        
        final prevAmplitude = _applySmoothingWindow(waveformData, i - 1);
        final prevWaveHeight = height * 0.4 * prevAmplitude;
        final prevUpperY = centerY - prevWaveHeight;
        final prevLowerY = centerY + prevWaveHeight;
        
        // Draw upper curve
        path.moveTo(prevX, prevUpperY);
        path.quadraticBezierTo(controlX, (prevUpperY + upperY) / 2, x, upperY);
        
        // Draw lower curve
        path.moveTo(prevX, prevLowerY);
        path.quadraticBezierTo(controlX, (prevLowerY + lowerY) / 2, x, lowerY);
        
        // Fill path
        if (i == 1) {
          fillPath.lineTo(x, upperY);
        } else {
          fillPath.quadraticBezierTo(controlX, (prevUpperY + upperY) / 2, x, upperY);
        }
      }
    }
    
    // Complete fill path
    for (int i = waveformData.length - 1; i >= 0; i--) {
      final x = (i / (waveformData.length - 1)) * width;
      final amplitude = _applySmoothingWindow(waveformData, i);
      final waveHeight = height * 0.4 * amplitude;
      final lowerY = centerY + waveHeight;
      
      if (i == waveformData.length - 1) {
        fillPath.lineTo(x, lowerY);
      } else {
        final nextX = ((i + 1) / (waveformData.length - 1)) * width;
        final controlX = (x + nextX) / 2;
        final nextAmplitude = _applySmoothingWindow(waveformData, i + 1);
        final nextWaveHeight = height * 0.4 * nextAmplitude;
        final nextLowerY = centerY + nextWaveHeight;
        
        fillPath.quadraticBezierTo(controlX, (lowerY + nextLowerY) / 2, x, lowerY);
      }
    }
    
    fillPath.close();
    
    // Draw filled area first
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw waveform outline
    canvas.drawPath(path, paint);
    
    // Add glow effect for active state
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawPath(path, glowPaint);
    }
  }

  double _applySmoothingWindow(List<double> data, int index) {
    const windowSize = 3;
    double sum = 0;
    int count = 0;
    
    for (int i = index - windowSize ~/ 2; i <= index + windowSize ~/ 2; i++) {
      if (i >= 0 && i < data.length) {
        sum += data[i];
        count++;
      }
    }
    
    return count > 0 ? sum / count : 0;
  }

  @override
  bool shouldRepaint(SmoothWaveformPainter oldDelegate) {
    return waveformData != oldDelegate.waveformData ||
           color != oldDelegate.color ||
           isActive != oldDelegate.isActive;
  }
}