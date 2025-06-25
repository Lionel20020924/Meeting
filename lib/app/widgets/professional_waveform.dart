import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProfessionalWaveform extends StatefulWidget {
  final List<double> waveformData;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;
  final bool showMirror;

  const ProfessionalWaveform({
    super.key,
    required this.waveformData,
    this.height = 120,
    this.primaryColor = const Color(0xFFFF4444),
    this.secondaryColor = const Color(0xFFFF8888),
    this.isActive = true,
    this.showMirror = true,
  });

  @override
  State<ProfessionalWaveform> createState() => _ProfessionalWaveformState();
}

class _ProfessionalWaveformState extends State<ProfessionalWaveform>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProfessionalWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _pulseController]),
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: ProfessionalWaveformPainter(
              waveformData: widget.waveformData,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              isActive: widget.isActive,
              showMirror: widget.showMirror,
              shimmerProgress: _shimmerController.value,
              pulseProgress: _pulseController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class ProfessionalWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;
  final bool showMirror;
  final double shimmerProgress;
  final double pulseProgress;

  ProfessionalWaveformPainter({
    required this.waveformData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
    required this.showMirror,
    required this.shimmerProgress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Draw center line
    final centerLinePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(0, centerY),
      Offset(width, centerY),
      centerLinePaint,
    );

    // Calculate bar dimensions
    final barCount = waveformData.length;
    final barSpacing = 2.0;
    final barWidth = math.max(1.0, (width - (barCount - 1) * barSpacing) / barCount);
    
    // Draw waveform bars
    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final amplitude = waveformData[i];
      
      // Apply pulse effect
      final pulseFactor = 1.0 + (pulseProgress * 0.1 * amplitude);
      
      // Calculate bar height with minimum visible height
      final maxBarHeight = showMirror ? height * 0.45 : height * 0.9;
      final minBarHeight = 2.0;
      final barHeight = minBarHeight + (maxBarHeight - minBarHeight) * amplitude * pulseFactor;
      
      // Calculate positions
      final topY = showMirror ? centerY - barHeight : height - barHeight;
      final bottomY = showMirror ? centerY + barHeight : height;
      
      // Create gradient for each bar
      final barRect = Rect.fromLTWH(x, topY, barWidth, bottomY - topY);
      
      // Apply shimmer effect
      final shimmerOffset = (shimmerProgress * width * 2) - width;
      final distanceFromShimmer = (x - shimmerOffset).abs() / width;
      final shimmerIntensity = math.max(0, 1 - distanceFromShimmer * 2);
      
      // Create gradient paint
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: showMirror ? [
            secondaryColor.withValues(alpha: 0.3 + shimmerIntensity * 0.3),
            primaryColor.withValues(alpha: 0.8 + shimmerIntensity * 0.2),
            primaryColor.withValues(alpha: 0.8 + shimmerIntensity * 0.2),
            secondaryColor.withValues(alpha: 0.3 + shimmerIntensity * 0.3),
          ] : [
            secondaryColor.withValues(alpha: 0.3 + shimmerIntensity * 0.3),
            primaryColor.withValues(alpha: 0.8 + shimmerIntensity * 0.2),
          ],
          stops: showMirror ? const [0.0, 0.45, 0.55, 1.0] : null,
        ).createShader(barRect);
      
      // Draw main bar
      final barPath = Path();
      final radius = barWidth * 0.3;
      
      if (showMirror) {
        // Top part
        barPath.moveTo(x, centerY);
        barPath.lineTo(x, centerY - barHeight + radius);
        barPath.quadraticBezierTo(
          x + barWidth / 2, centerY - barHeight,
          x + barWidth, centerY - barHeight + radius,
        );
        barPath.lineTo(x + barWidth, centerY);
        
        // Bottom part
        barPath.lineTo(x + barWidth, centerY + barHeight - radius);
        barPath.quadraticBezierTo(
          x + barWidth / 2, centerY + barHeight,
          x, centerY + barHeight - radius,
        );
        barPath.close();
      } else {
        barPath.addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topY, barWidth, barHeight),
          Radius.circular(radius),
        ));
      }
      
      canvas.drawPath(barPath, gradientPaint);
      
      // Add glow effect for high amplitude
      if (amplitude > 0.5 && isActive) {
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              primaryColor.withValues(alpha: 0.3 * amplitude),
              primaryColor.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(
            center: Offset(x + barWidth / 2, centerY),
            radius: barHeight,
          ))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        
        canvas.drawPath(barPath, glowPaint);
      }
    }
    
    // Add subtle grid lines
    final gridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    
    // Horizontal grid lines
    for (int i = 1; i < 4; i++) {
      final y = height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(ProfessionalWaveformPainter oldDelegate) {
    return waveformData != oldDelegate.waveformData ||
           primaryColor != oldDelegate.primaryColor ||
           isActive != oldDelegate.isActive ||
           shimmerProgress != oldDelegate.shimmerProgress ||
           pulseProgress != oldDelegate.pulseProgress;
  }
}

// Spectrum-style waveform visualization
class SpectrumWaveform extends StatefulWidget {
  final List<double> waveformData;
  final double height;
  final List<Color> colors;
  final bool isActive;

  const SpectrumWaveform({
    super.key,
    required this.waveformData,
    this.height = 120,
    this.colors = const [
      Color(0xFF00FF00),  // Green for low
      Color(0xFFFFFF00),  // Yellow for medium
      Color(0xFFFF0000),  // Red for high
    ],
    this.isActive = true,
  });

  @override
  State<SpectrumWaveform> createState() => _SpectrumWaveformState();
}

class _SpectrumWaveformState extends State<SpectrumWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _decayController;
  final List<double> _peakLevels = [];
  final List<double> _currentLevels = [];
  
  @override
  void initState() {
    super.initState();
    _decayController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    
    // Initialize levels
    _peakLevels.addAll(List.filled(widget.waveformData.length, 0.0));
    _currentLevels.addAll(List.filled(widget.waveformData.length, 0.0));
    
    _decayController.addListener(_updateLevels);
    if (widget.isActive) {
      _decayController.repeat();
    }
  }
  
  void _updateLevels() {
    setState(() {
      for (int i = 0; i < widget.waveformData.length && i < _currentLevels.length; i++) {
        // Update current levels with smooth transition
        final target = widget.waveformData[i];
        final current = _currentLevels[i];
        _currentLevels[i] = current + (target - current) * 0.3;
        
        // Update peak levels
        if (_currentLevels[i] > _peakLevels[i]) {
          _peakLevels[i] = _currentLevels[i];
        } else {
          // Slowly decay peak levels
          _peakLevels[i] = math.max(0, _peakLevels[i] - 0.01);
        }
      }
    });
  }

  @override
  void didUpdateWidget(SpectrumWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Adjust array sizes if needed
    while (_peakLevels.length < widget.waveformData.length) {
      _peakLevels.add(0.0);
      _currentLevels.add(0.0);
    }
    while (_peakLevels.length > widget.waveformData.length) {
      _peakLevels.removeLast();
      _currentLevels.removeLast();
    }
    
    if (widget.isActive && !oldWidget.isActive) {
      _decayController.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _decayController.stop();
    }
  }

  @override
  void dispose() {
    _decayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: SpectrumWaveformPainter(
          currentLevels: _currentLevels,
          peakLevels: _peakLevels,
          colors: widget.colors,
          isActive: widget.isActive,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class SpectrumWaveformPainter extends CustomPainter {
  final List<double> currentLevels;
  final List<double> peakLevels;
  final List<Color> colors;
  final bool isActive;

  SpectrumWaveformPainter({
    required this.currentLevels,
    required this.peakLevels,
    required this.colors,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentLevels.isEmpty) return;

    final width = size.width;
    final height = size.height;
    
    // Calculate bar dimensions
    final barCount = currentLevels.length;
    final totalSpacing = width * 0.3;
    final barSpacing = totalSpacing / (barCount + 1);
    final barWidth = (width - totalSpacing) / barCount;
    
    // LED segment height
    final segmentHeight = 3.0;
    final segmentSpacing = 1.0;
    final segmentsPerBar = (height / (segmentHeight + segmentSpacing)).floor();
    
    for (int i = 0; i < barCount; i++) {
      final x = barSpacing + i * (barWidth + barSpacing);
      final level = currentLevels[i];
      final peakLevel = peakLevels[i];
      
      // Calculate how many segments to light up
      final litSegments = (segmentsPerBar * level).round();
      final peakSegment = (segmentsPerBar * peakLevel).round();
      
      // Draw segments
      for (int j = 0; j < segmentsPerBar; j++) {
        final y = height - (j + 1) * (segmentHeight + segmentSpacing);
        final segmentLevel = j / segmentsPerBar;
        
        Color segmentColor;
        double opacity;
        
        if (j < litSegments) {
          // Active segment
          if (segmentLevel < 0.5) {
            segmentColor = colors[0]; // Green
          } else if (segmentLevel < 0.8) {
            segmentColor = colors[1]; // Yellow
          } else {
            segmentColor = colors[2]; // Red
          }
          opacity = isActive ? 0.9 : 0.6;
        } else if (j == peakSegment) {
          // Peak indicator
          segmentColor = colors[2]; // Red
          opacity = isActive ? 0.8 : 0.5;
        } else {
          // Inactive segment
          segmentColor = colors[0];
          opacity = 0.1;
        }
        
        final segmentRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, segmentHeight),
          Radius.circular(segmentHeight / 2),
        );
        
        final segmentPaint = Paint()
          ..color = segmentColor.withValues(alpha: opacity);
        
        canvas.drawRRect(segmentRect, segmentPaint);
        
        // Add glow for lit segments
        if (j < litSegments && isActive) {
          final glowPaint = Paint()
            ..color = segmentColor.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          
          canvas.drawRRect(segmentRect, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SpectrumWaveformPainter oldDelegate) {
    return currentLevels != oldDelegate.currentLevels ||
           peakLevels != oldDelegate.peakLevels ||
           isActive != oldDelegate.isActive;
  }
}