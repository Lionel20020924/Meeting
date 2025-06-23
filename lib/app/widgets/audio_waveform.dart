import 'dart:math';
import 'package:flutter/material.dart';

class AudioWaveform extends StatefulWidget {
  final double height;
  final Color color;
  final int barCount;
  final Duration animationDuration;
  final bool isActive;

  const AudioWaveform({
    super.key,
    this.height = 100,
    this.color = Colors.blue,
    this.barCount = 50,
    this.animationDuration = const Duration(milliseconds: 100),
    this.isActive = true,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: widget.animationDuration.inMilliseconds +
              _random.nextInt(300),
        ),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 20), () {
        if (mounted) {
          _animateBar(i);
        }
      });
    }
  }

  void _animateBar(int index) {
    if (!mounted || !widget.isActive) return;

    final controller = _controllers[index];
    final targetHeight = 0.1 + _random.nextDouble() * 0.9;

    controller.animateTo(
      targetHeight,
      duration: Duration(
        milliseconds: 100 + _random.nextInt(200),
      ),
      curve: Curves.easeInOut,
    ).then((_) {
      if (mounted && widget.isActive) {
        Future.delayed(
          Duration(milliseconds: _random.nextInt(100)),
          () => _animateBar(index),
        );
      }
    });
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _stopAnimations() {
    for (final controller in _controllers) {
      controller.stop();
      controller.animateTo(0.1, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 3,
                height: widget.height * _animations[index].value,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha: 0.7 + (_animations[index].value * 0.3),
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// 简化版波形组件（用于静态显示）
class SimpleWaveform extends StatelessWidget {
  final double height;
  final Color color;
  final int barCount;
  final List<double>? values;

  const SimpleWaveform({
    super.key,
    this.height = 60,
    this.color = Colors.blue,
    this.barCount = 30,
    this.values,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(42); // 固定种子确保一致性
    final barValues = values ??
        List.generate(
          barCount,
          (index) => 0.2 + random.nextDouble() * 0.6,
        );

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          return Container(
            width: 3,
            height: height * barValues[index],
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}