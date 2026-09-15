import 'package:flutter/material.dart';
import 'dart:math' as math;

class EnhanceSoundScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Function(double bass, double immersive) onEffectsChanged;

  const EnhanceSoundScreen({
    super.key,
    required this.isDarkTheme,
    required this.onEffectsChanged,
  });

  @override
  State<EnhanceSoundScreen> createState() => _EnhanceSoundScreenState();
}

class _EnhanceSoundScreenState extends State<EnhanceSoundScreen> {
  double _bassLevel = 0.3;
  double _immersiveLevel = 0.3;

  @override
  void initState() {
    super.initState();
    _applyEffects();
  }

  void _applyEffects() {
    widget.onEffectsChanged(_bassLevel, _immersiveLevel);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enhance sound',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.headphones, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Put in earphones before adjusting sound effects',
                    style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularDial(
                  value: _bassLevel,
                  label: 'Bass',
                  isDark: isDark,
                  onChanged: (value) {
                    setState(() => _bassLevel = value);
                    _applyEffects();
                  },
                ),
                _buildCircularDial(
                  value: _immersiveLevel,
                  label: 'Immersive audio',
                  isDark: isDark,
                  onChanged: (value) {
                    setState(() => _immersiveLevel = value);
                    _applyEffects();
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq, color: Colors.deepPurpleAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Bass: ${(_bassLevel * 100).toStringAsFixed(0)}%  |  '
                      'Immersive: ${(_immersiveLevel * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _bassLevel = 0.3;
                    _immersiveLevel = 0.3;
                  });
                  _applyEffects();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restore, color: Colors.deepPurpleAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Reset to default',
                        style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularDial({
    required double value,
    required String label,
    required bool isDark,
    required Function(double) onChanged,
  }) {
    const double size = 160;
    const double dialRadius = 60;
    const int totalDots = 30;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            final newValue = (value + details.delta.dx / 200).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          onTapDown: (details) {
            final localPos = details.localPosition;
            final center = const Offset(size / 2, size / 2);
            final dx = localPos.dx - center.dx;
            final dy = localPos.dy - center.dy;
            double angle = math.atan2(dx, -dy);
            if (angle < 0) angle += 2 * math.pi;
            final newValue = (angle / (2 * math.pi)).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CircularDialPainter(
                value: value,
                isDark: isDark,
                totalDots: totalDots,
                dialRadius: dialRadius,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CircularDialPainter extends CustomPainter {
  final double value;
  final bool isDark;
  final int totalDots;
  final double dialRadius;

  _CircularDialPainter({
    required this.value,
    required this.isDark,
    required this.totalDots,
    required this.dialRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final activeColor = Colors.deepPurple.shade400;
    final inactiveColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final ringColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, dialRadius - 18, ringPaint);

    final dotRadius = dialRadius + 5;
    final activeDots = (value * totalDots).round();

    for (int i = 0; i < totalDots; i++) {
      final angle = -math.pi / 2 + (i / totalDots) * 2 * math.pi;
      final dotCenter = Offset(
        center.dx + dotRadius * math.cos(angle),
        center.dy + dotRadius * math.sin(angle),
      );
      final isActive = i < activeDots;
      final dotPaint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      final r = isActive ? 5.0 : 3.5;
      canvas.drawCircle(dotCenter, r, dotPaint);
    }

    final indicatorAngle = -math.pi / 2 + value * 2 * math.pi;
    final needleInner = dialRadius * 0.35;
    final needleOuter = dialRadius * 0.55;

    final needleStart = Offset(
      center.dx + needleInner * math.cos(indicatorAngle),
      center.dy + needleInner * math.sin(indicatorAngle),
    );
    final needleEnd = Offset(
      center.dx + needleOuter * math.cos(indicatorAngle),
      center.dy + needleOuter * math.sin(indicatorAngle),
    );

    final needlePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(needleStart, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _CircularDialPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isDark != isDark;
  }
}
