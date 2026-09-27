import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'services/audio_handler.dart';

class EqualizerScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Color accentColor;
  final List<Color> gradientColors;

  const EqualizerScreen({
    super.key,
    required this.isDarkTheme,
    required this.accentColor,
    required this.gradientColors,
  });

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  int _numBands = 5;
  int _minLevel = -1500;
  int _maxLevel = 1500;
  List<int> _centerFreqs = [60, 230, 910, 3600, 14000];
  List<int> _bandLevels = [0, 0, 0, 0, 0];
  String _selectedPreset = 'Flat';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Flat', 'emoji': '➖', 'color': 0xFF6B7280},
    {'name': 'Rock', 'emoji': '🎸', 'color': 0xFFEF4444},
    {'name': 'Pop', 'emoji': '🎤', 'color': 0xFFEC4899},
    {'name': 'Jazz', 'emoji': '🎷', 'color': 0xFFF59E0B},
    {'name': 'Classical', 'emoji': '🎻', 'color': 0xFF8B5CF6},
    {'name': 'BassBoost', 'emoji': '🔥', 'color': 0xFFDC2626},
    {'name': 'TrebleBoost', 'emoji': '✨', 'color': 0xFF06B6D4},
    {'name': 'Vocal', 'emoji': '🎙️', 'color': 0xFF10B981},
  ];

  @override
  void initState() {
    super.initState();
    _loadEqualizerInfo();
  }

  Future<void> _loadEqualizerInfo() async {
    if (audioHandler == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final info = await audioHandler!.getEqualizerInfo();
      final numBands = info['numBands'] as int? ?? 5;
      final freqs = (info['centerFreqs'] as List?)?.cast<int>() ?? [];
      setState(() {
        _numBands = numBands > 0 ? numBands : 5;
        _minLevel = info['minLevel'] as int? ?? -1500;
        _maxLevel = info['maxLevel'] as int? ?? 1500;
        if (freqs.isNotEmpty) _centerFreqs = freqs;
        _bandLevels = List.filled(_numBands, 0);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('EQ info error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatFreq(int hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    return '$hz';
  }

  Future<void> _applyPreset(String presetName) async {
    if (audioHandler == null) return;
    setState(() {
      _selectedPreset = presetName;
      _bandLevels = _getPresetBands(presetName);
    });
    await audioHandler!.setEqualizerPreset(presetName);
  }

  List<int> _getPresetBands(String presetName) {
    final levels = List<int>.filled(_numBands, 0);
    for (int i = 0; i < _numBands; i++) {
      final freq = i < _centerFreqs.length ? _centerFreqs[i] : 0;
      levels[i] = switch (presetName) {
        'Rock' => freq < 200 ? 600 : freq < 1000 ? -200 : freq < 4000 ? 300 : 700,
        'Pop' => freq < 200 ? 300 : freq < 1000 ? 500 : freq < 4000 ? 400 : 200,
        'Jazz' => freq < 200 ? 400 : freq < 1000 ? 200 : freq < 4000 ? 300 : 500,
        'Classical' => freq < 200 ? 400 : freq < 1000 ? 0 : freq < 4000 ? 300 : 600,
        'BassBoost' => freq < 200 ? 1200 : freq < 1000 ? 700 : freq < 4000 ? 200 : 0,
        'TrebleBoost' => freq < 200 ? 0 : freq < 1000 ? 100 : freq < 4000 ? 700 : 1200,
        'Vocal' => freq < 200 ? -300 : freq < 1000 ? 600 : freq < 4000 ? 700 : 300,
        _ => 0,
      };
    }
    return levels;
  }

  Future<void> _onBandChanged(int index, int newLevel) async {
    if (audioHandler == null) return;
    setState(() {
      _bandLevels[index] = newLevel;
      _selectedPreset = 'Custom';
    });
    await audioHandler!.setEqualizerBand(index, newLevel);
  }

  void _resetToFlat() => _applyPreset('Flat');

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final bg = isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB);
    final card = isDark ? const Color(0xFF181820) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final activeColor = _selectedPreset == 'Custom'
        ? widget.accentColor
        : Color(_presets.firstWhere(
            (p) => p['name'] == _selectedPreset,
            orElse: () => _presets[0],
          )['color']);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Equalizer',
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_selectedPreset != 'Flat')
            IconButton(
              icon: Icon(Icons.refresh, color: widget.accentColor),
              tooltip: 'Reset',
              onPressed: _resetToFlat,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Frequency Response Curve Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [card, card.withOpacity(0.6)]
                            : [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: activeColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _presets.firstWhere(
                                      (p) => p['name'] == _selectedPreset,
                                      orElse: () => _presets[0],
                                    )['emoji'] as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedPreset,
                                    style: TextStyle(
                                      color: activeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.graphic_eq, color: subText, size: 16),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ✅ Live Frequency Curve
                        SizedBox(
                          height: 90,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _FrequencyCurvePainter(
                              bandLevels: _bandLevels,
                              centerFreqs: _centerFreqs,
                              minLevel: _minLevel,
                              maxLevel: _maxLevel,
                              activeColor: activeColor,
                              gridColor: subText.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ Preset section
                  Row(
                    children: [
                      Text(
                        'PRESETS',
                        style: TextStyle(
                          color: subText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_presets.length} available',
                        style: TextStyle(color: subText, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final p = _presets[i];
                        final isActive = _selectedPreset == p['name'];
                        final pColor = Color(p['color'] as int);
                        return GestureDetector(
                          onTap: () => _applyPreset(p['name'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(
                                      colors: [
                                        pColor,
                                        pColor.withOpacity(0.7),
                                      ],
                                    )
                                  : null,
                              color: isActive ? null : card,
                              borderRadius: BorderRadius.circular(21),
                              border: isActive
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200,
                                    ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: pColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(p['emoji'] as String,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  p['name'] as String,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : textColor,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ✅ Bands section
                  Row(
                    children: [
                      Text(
                        'BANDS',
                        style: TextStyle(
                          color: subText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_minLevel ~/ 100} dB  ↔  +${_maxLevel ~/ 100} dB',
                        style: TextStyle(color: subText, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left dB labels
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Column(
                            children: [
                              Text('+15',
                                  style: TextStyle(
                                      color: subText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 30),
                              Text('0',
                                  style: TextStyle(
                                      color: subText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 30),
                              Text('-15',
                                  style: TextStyle(
                                      color: subText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(_numBands, (i) {
                              final freq =
                                  i < _centerFreqs.length ? _centerFreqs[i] : 0;
                              return _buildBand(i, _formatFreq(freq), activeColor,
                                  isDark, card);
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ✅ Reset button
                  Center(
                    child: GestureDetector(
                      onTap: _resetToFlat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradientColors[0].withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restore, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Reset to Flat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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

  Widget _buildBand(
    int index,
    String label,
    Color activeColor,
    bool isDark,
    Color card,
  ) {
    final level = _bandLevels[index];
    final double normalized = level / _maxLevel;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: level != 0
                  ? activeColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level == 0 ? '0' : '${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',
              style: TextStyle(
                color: level != 0 ? activeColor : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Vertical slider
          SizedBox(
            height: 180,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  thumbColor: activeColor,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                    elevation: 4,
                  ),
                  overlayColor: activeColor.withOpacity(0.2),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: level.toDouble().clamp(
                        _minLevel.toDouble(),
                        _maxLevel.toDouble(),
                      ),
                  min: _minLevel.toDouble(),
                  max: _maxLevel.toDouble(),
                  onChanged: (v) => _onBandChanged(index, v.round()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Freq label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Live Frequency Curve Painter
class _FrequencyCurvePainter extends CustomPainter {
  final List<int> bandLevels;
  final List<int> centerFreqs;
  final int minLevel;
  final int maxLevel;
  final Color activeColor;
  final Color gridColor;

  _FrequencyCurvePainter({
    required this.bandLevels,
    required this.centerFreqs,
    required this.minLevel,
    required this.maxLevel,
    required this.activeColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw horizontal grid lines (0 dB baseline, top, bottom)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Top line (+15 dB)
    canvas.drawLine(
      Offset(0, size.height * 0.1),
      Offset(size.width, size.height * 0.1),
      gridPaint,
    );
    // Middle line (0 dB) — dashed look
    final dashPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, size.height * 0.5),
        Offset(x + 4, size.height * 0.5),
        dashPaint,
      );
    }
    // Bottom line (-15 dB)
    canvas.drawLine(
      Offset(0, size.height * 0.9),
      Offset(size.width, size.height * 0.9),
      gridPaint,
    );

    if (bandLevels.isEmpty) return;

    // Compute points for curve
    final points = <Offset>[];
    for (int i = 0; i < bandLevels.length; i++) {
      final x = (i / (bandLevels.length - 1)) * size.width;
      // Map level from min-max to bottom-top
      final levelNorm = bandLevels[i] / maxLevel; // -1 to +1
      final y = size.height * (0.5 - levelNorm * 0.4);
      points.add(Offset(x, y));
    }

    // Draw smooth curve using quadratic bezier
    final curvePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (points.length >= 2) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final midX = (prev.dx + curr.dx) / 2;
        final midY = (prev.dy + curr.dy) / 2;
        path.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
      }
      path.lineTo(points.last.dx, points.last.dy);
      canvas.drawPath(path, curvePaint);

      // Fill area below curve
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height * 0.5);
      fillPath.lineTo(0, size.height * 0.5);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            activeColor.withOpacity(0.35),
            activeColor.withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw dots at each band
    for (final p in points) {
      canvas.drawCircle(
        p,
        4.5,
        Paint()..color = activeColor,
      );
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyCurvePainter oldDelegate) {
    return oldDelegate.bandLevels != bandLevels ||
        oldDelegate.activeColor != activeColor;
  }
}
