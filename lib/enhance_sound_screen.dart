import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

class EnhanceSoundScreen extends StatefulWidget {
  final AudioPlayer player;
  final bool isDarkTheme;

  const EnhanceSoundScreen({
    super.key,
    required this.player,
    this.isDarkTheme = true,
  });

  @override
  State<EnhanceSoundScreen> createState() => _EnhanceSoundScreenState();
}

class _EnhanceSoundScreenState extends State<EnhanceSoundScreen> {
  double _bassLevel = 0.3; // 0.0 to 1.0
  double _immersiveLevel = 0.3; // 0.0 to 1.0

  @override
  void initState() {
    super.initState();
    _applyEffects();
  }

  Future<void> _applyEffects() async {
    // Bass effect - volume boost (simulated)
    final volume = 0.85 + (_bassLevel * 0.15);
    await widget.player.setVolume(volume.clamp(0.0, 1.0));

    // Immersive effect - balance (simulated)
    await widget.player.setBalance(_immersiveLevel * 0.8);
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
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
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
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Row(
              children: [
                Icon(
                  Icons.headphones,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Put in earphones before adjusting sound effects',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // Circular Dials
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bass Dial
                _buildCircularDial(
                  value: _bassLevel,
                  label: 'Bass',
                  isDark: isDark,
                  onChanged: (value) {
                    setState(() => _bassLevel = value);
                    _applyEffects();
                  },
                ),

                // Immersive Audio Dial
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

            const SizedBox(height: 60),

            // Reset Button
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restore, color: Colors.deepPurpleAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Reset to default',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.w600,
                        ),
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
            // Simple horizontal drag to change value
            final newValue = (value + details.delta.dx / 200).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          onTapDown: (details) {
            // Calculate angle from tap
            final localPos = details.localPosition;
            final center = const Offset(size / 2, size / 2);
            final dx = localPos.dx - center.dx;
            final dy = localPos.dy - center.dy;

            // Angle from top (12 o'clock) going clockwise
            double angle = math.atan2(dx, -dy);
            if (angle < 0) angle += 2 * math.pi;

            // Map 0 to 2π → 0 to 1
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
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ✅ Custom Painter for Circular Dots
class _CircularDialPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
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
    final inactiveColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final ringColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    // ✅ Background ring (thick grey circle)
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, dialRadius - 18, ringPaint);

    // ✅ Dots around the circle
    final dotRadius = dialRadius + 5;
    final activeDots = (value * totalDots).round();

    for (int i = 0; i < totalDots; i++) {
      // Start from top (-90°) going clockwise
      final angle = -math.pi / 2 + (i / totalDots) * 2 * math.pi;
      final dotCenter = Offset(
        center.dx + dotRadius * math.cos(angle),
        center.dy + dotRadius * math.sin(angle),
      );

      final isActive = i < activeDots;
      final dotPaint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      // Active dots are bigger, inactive smaller
      final r = isActive ? 5.0 : 3.5;
      canvas.drawCircle(dotCenter, r, dotPaint);
    }

    // ✅ Inner indicator line (like a needle)
    // Angle maps 0% to top (12 o'clock), 100% back to top going clockwise
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
