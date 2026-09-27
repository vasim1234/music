import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    {'name': 'Flat', 'emoji': '➖'},
    {'name': 'Rock', 'emoji': '🎸'},
    {'name': 'Pop', 'emoji': '🎤'},
    {'name': 'Jazz', 'emoji': '🎷'},
    {'name': 'Classical', 'emoji': '🎻'},
    {'name': 'BassBoost', 'emoji': '🔥'},
    {'name': 'TrebleBoost', 'emoji': '✨'},
    {'name': 'Vocal', 'emoji': '🎙️'},
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
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)}k';
    return '${hz}';
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
        'Rock' => freq < 200
            ? 600
            : freq < 1000
                ? -200
                : freq < 4000
                    ? 300
                    : 700,
        'Pop' => freq < 200
            ? 300
            : freq < 1000
                ? 500
                : freq < 4000
                    ? 400
                    : 200,
        'Jazz' => freq < 200
            ? 400
            : freq < 1000
                ? 200
                : freq < 4000
                    ? 300
                    : 500,
        'Classical' => freq < 200
            ? 400
            : freq < 1000
                ? 0
                : freq < 4000
                    ? 300
                    : 600,
        'BassBoost' => freq < 200
            ? 1200
            : freq < 1000
                ? 700
                : freq < 4000
                    ? 200
                    : 0,
        'TrebleBoost' => freq < 200
            ? 0
            : freq < 1000
                ? 100
                : freq < 4000
                    ? 700
                    : 1200,
        'Vocal' => freq < 200
            ? -300
            : freq < 1000
                ? 600
                : freq < 4000
                    ? 700
                    : 300,
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

  void _resetToFlat() {
    _applyPreset('Flat');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final bg = isDark ? const Color(0xFF0F0F14) : Colors.white;
    final card = isDark ? const Color(0xFF181820) : const Color(0xFFF5F5F7);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

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
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: widget.accentColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preset info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.equalizer,
                          color: widget.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Preset: $_selectedPreset',
                          style: TextStyle(
                            color: widget.accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Preset chips
                  Text(
                    'PRESETS',
                    style: TextStyle(
                      color: subText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _presets.map((p) {
                      final isActive = _selectedPreset == p['name'];
                      return GestureDetector(
                        onTap: () => _applyPreset(p['name'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? LinearGradient(colors: widget.gradientColors)
                                : null,
                            color: isActive ? null : card,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p['emoji'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p['name'] as String,
                                style: TextStyle(
                                  color: isActive ? Colors.white : textColor,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 35),

                  // Band sliders
                  Text(
                    'BANDS',
                    style: TextStyle(
                      color: subText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 320,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_numBands, (i) {
                        final freq = i < _centerFreqs.length
                            ? _centerFreqs[i]
                            : 0;
                        return _buildVerticalBand(
                          index: i,
                          label: _formatFreq(freq),
                          isDark: isDark,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Reset button
                  Center(
                    child: GestureDetector(
                      onTap: _resetToFlat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restore,
                              color: widget.accentColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reset to Flat',
                              style: TextStyle(
                                color: widget.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildVerticalBand({
    required int index,
    required String label,
    required bool isDark,
  }) {
    final level = _bandLevels[index];
    final maxAbs = _maxLevel > 0 ? _maxLevel : 1500;
    // level / maxAbs se -1.0 se +1.0 value
    final double normalized = level / maxAbs;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Level text
        Text(
          '${(level / 100).toStringAsFixed(0)}',
          style: TextStyle(
            color: widget.accentColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),

        // Vertical slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: widget.accentColor,
                inactiveTrackColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
                thumbColor: widget.accentColor,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: level.toDouble().clamp(
                      _minLevel.toDouble(),
                      _maxLevel.toDouble(),
                    ),
                min: _minLevel.toDouble(),
                max: _maxLevel.toDouble(),
                onChanged: (v) {
                  _onBandChanged(index, v.round());
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Frequency label
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
