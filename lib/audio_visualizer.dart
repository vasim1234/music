import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color accentColor;
  final int barCount;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    required this.accentColor,
    this.barCount = 32,
    this.height = 60,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _barHeights;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.filled(widget.barCount, 0.3);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_updateBars);

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  void _updateBars() {
    if (!widget.isPlaying) return;
    setState(() {
      for (int i = 0; i < widget.barCount; i++) {
        // Bass-heavy — left side zyada move
        final bassFactor = 1.0 - (i / widget.barCount) * 0.6;
        final target = 0.2 + _random.nextDouble() * 0.8 * bassFactor;
        // Smooth transition
        _barHeights[i] = _barHeights[i] * 0.6 + target * 0.4;
      }
    });
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
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
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final barHeight = _barHeights[index] * widget.height;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 4,
            height: barHeight.clamp(4.0, widget.height),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  widget.accentColor,
                  widget.accentColor.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
