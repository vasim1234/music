import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'services/audio_handler.dart';

class AudioSettingsScreen extends StatefulWidget {
  final bool isDarkTheme;
  final Color accentColor;
  final List<Color> gradientColors;

  const AudioSettingsScreen({
    super.key,
    required this.isDarkTheme,
    required this.accentColor,
    required this.gradientColors,
  });

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  // Bass + Immersive
  double _bassLevel = 0.3;
  double _immersiveLevel = 0.3;

  // Equalizer
  int _numBands = 5;
  int _minLevel = -1500;
  int _maxLevel = 1500;
  List<int> _centerFreqs = [60, 230, 910, 3600, 14000];
  List<int> _bandLevels = [0, 0, 0, 0, 0];
  String _selectedPreset = 'Flat';
  bool _isLoading = true;

  // Reverb + Loudness
  String _selectedReverb = 'None';
  bool _reverbEnabled = false;
  bool _loudnessEnabled = false;
  int _loudnessGain = 500;

  // Custom Presets
  List<Map<String, dynamic>> _customPresets = [];

  final List<Map<String, dynamic>> _builtinPresets = [
    {'name': 'Flat', 'emoji': '➖', 'color': 0xFF6B7280},
    {'name': 'Rock', 'emoji': '🎸', 'color': 0xFFEF4444},
    {'name': 'Pop', 'emoji': '🎤', 'color': 0xFFEC4899},
    {'name': 'Jazz', 'emoji': '🎷', 'color': 0xFFF59E0B},
    {'name': 'Classical', 'emoji': '🎻', 'color': 0xFF8B5CF6},
    {'name': 'BassBoost', 'emoji': '🔥', 'color': 0xFFDC2626},
    {'name': 'TrebleBoost', 'emoji': '✨', 'color': 0xFF06B6D4},
    {'name': 'Vocal', 'emoji': '🎙️', 'color': 0xFF10B981},
  ];

  final List<Map<String, dynamic>> _reverbPresets = [
    {'name': 'None', 'emoji': '🚫', 'label': 'Off'},
    {'name': 'SmallRoom', 'emoji': '🚪', 'label': 'Small Room'},
    {'name': 'MediumRoom', 'emoji': '🏠', 'label': 'Medium Room'},
    {'name': 'LargeRoom', 'emoji': '🏛️', 'label': 'Large Room'},
    {'name': 'MediumHall', 'emoji': '🎭', 'label': 'Medium Hall'},
    {'name': 'LargeHall', 'emoji': '🏟️', 'label': 'Large Hall'},
    {'name': 'Plate', 'emoji': '🎚️', 'label': 'Plate'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEqualizerInfo();
    _loadCustomPresets();
    _loadSavedState();
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
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('EQ info error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('custom_eq_presets');
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        setState(() {
          _customPresets =
              list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } catch (e) {
        debugPrint('Custom presets load error: $e');
      }
    }
  }

  Future<void> _saveCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_eq_presets', jsonEncode(_customPresets));
  }

  // ✅ UPDATED: Poora state load karo (EQ + Reverb + Loudness + Bass)
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load all saved values
    final savedBass = prefs.getDouble('bass_level') ?? 0.3;
    final savedImmersive = prefs.getDouble('immersive_level') ?? 0.3;
    final savedReverbEnabled = prefs.getBool('reverb_enabled') ?? false;
    final savedReverb = prefs.getString('reverb_preset') ?? 'None';
    final savedLoudnessEnabled = prefs.getBool('loudness_enabled') ?? false;
    final savedLoudnessGain = prefs.getInt('loudness_gain') ?? 500;
    
    // ✅ NAYA: EQ preset + bands load karo
    final savedPreset = prefs.getString('eq_preset') ?? 'Flat';
    final savedBands = prefs.getStringList('eq_bands');
    
    setState(() {
      _bassLevel = savedBass;
      _immersiveLevel = savedImmersive;
      _reverbEnabled = savedReverbEnabled;
      _selectedReverb = savedReverb;
      _loudnessEnabled = savedLoudnessEnabled;
      _loudnessGain = savedLoudnessGain;
      _selectedPreset = savedPreset;
      
      if (savedBands != null && savedBands.isNotEmpty) {
        _bandLevels = savedBands.map((s) => int.tryParse(s) ?? 0).toList();
      }
    });
    
    // Apply to audio handler
    if (audioHandler != null) {
      await audioHandler!.setBassBoost(_bassLevel > 0, (_bassLevel * 1000).round());
      await audioHandler!.setImmersive(_immersiveLevel > 0, (_immersiveLevel * 1000).round());
      
      // ✅ NAYA: Apply EQ preset
      if (savedPreset != 'Flat' && savedPreset != 'Custom') {
        await audioHandler!.setEqualizerPreset(savedPreset);
      }
      
      // ✅ NAYA: Apply individual bands
      if (savedBands != null) {
        for (int i = 0; i < savedBands.length; i++) {
          await audioHandler!.setEqualizerBand(i, int.tryParse(savedBands[i]) ?? 0);
        }
      }
      
      if (_reverbEnabled && _selectedReverb != 'None') {
        await audioHandler!.setReverb(true, _selectedReverb);
      }
      if (_loudnessEnabled) {
        await audioHandler!.setLoudness(true, _loudnessGain);
      }
    }
  }

  // ✅ UPDATED: Poora state save karo (EQ + Reverb + Loudness + Bass)
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bass_level', _bassLevel);
    await prefs.setDouble('immersive_level', _immersiveLevel);
    await prefs.setBool('reverb_enabled', _reverbEnabled);
    await prefs.setString('reverb_preset', _selectedReverb);
    await prefs.setBool('loudness_enabled', _loudnessEnabled);
    await prefs.setInt('loudness_gain', _loudnessGain);
    
    // ✅ NAYA: EQ preset + bands save karo
    await prefs.setString('eq_preset', _selectedPreset);
    await prefs.setStringList('eq_bands', _bandLevels.map((e) => e.toString()).toList());
  }

  Future<void> _applyBassImmersive() async {
    if (audioHandler == null) return;
    await audioHandler!
        .setBassBoost(_bassLevel > 0, (_bassLevel * 1000).round());
    await audioHandler!
        .setImmersive(_immersiveLevel > 0, (_immersiveLevel * 1000).round());
    await _saveState();
  }

  String _formatFreq(int hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    }
    return '$hz';
  }

  // ✅ UPDATED: Preset apply + save
  Future<void> _applyPreset(String presetName) async {
    if (audioHandler == null) return;
    setState(() {
      _selectedPreset = presetName;
      _bandLevels = _getPresetBands(presetName);
    });
    await audioHandler!.setEqualizerPreset(presetName);
    await _saveState();   // ✅ NAYA: Save karo
  }

  Future<void> _applyCustomPreset(Map<String, dynamic> preset) async {
    if (audioHandler == null) return;
    final levels = (preset['levels'] as List).cast<int>();
    setState(() {
      _selectedPreset = preset['name'] as String;
      _bandLevels = List.from(levels);
    });
    for (int i = 0; i < levels.length; i++) {
      await audioHandler!.setEqualizerBand(i, levels[i]);
    }
    await _saveState();   // ✅ NAYA: Save karo
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

  // ✅ UPDATED: Band change + save
  Future<void> _onBandChanged(int index, int newLevel) async {
    if (audioHandler == null) return;
    setState(() {
      _bandLevels[index] = newLevel;
      _selectedPreset = 'Custom';
    });
    await audioHandler!.setEqualizerBand(index, newLevel);
    await _saveState();   // ✅ NAYA: Save karo
  }

  Future<void> _onReverbChanged(String presetName) async {
    final enabled = presetName != 'None';
    setState(() {
      _selectedReverb = presetName;
      _reverbEnabled = enabled;
    });
    if (audioHandler != null) {
      await audioHandler!.setReverb(enabled, presetName);
    }
    await _saveState();
  }

  Future<void> _onLoudnessToggle(bool enabled) async {
    setState(() => _loudnessEnabled = enabled);
    if (audioHandler != null) {
      await audioHandler!.setLoudness(enabled, enabled ? _loudnessGain : 0);
    }
    await _saveState();
  }

  Future<void> _onLoudnessGainChanged(int gain) async {
    setState(() => _loudnessGain = gain);
    if (audioHandler != null && _loudnessEnabled) {
      await audioHandler!.setLoudness(true, gain);
    }
    await _saveState();
  }

  void _resetAll() {
    setState(() {
      _bassLevel = 0.3;
      _immersiveLevel = 0.3;
      _selectedPreset = 'Flat';
      _bandLevels = List.filled(_numBands, 0);
      _selectedReverb = 'None';
      _reverbEnabled = false;
      _loudnessEnabled = false;
      _loudnessGain = 500;
    });
    _applyBassImmersive();
    _applyPreset('Flat');
    _onReverbChanged('None');
    _onLoudnessToggle(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final bg = isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB);
    final card = isDark ? const Color(0xFF181820) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final activeColor = _selectedPreset == 'Custom' || _isCustomSelected()
        ? widget.accentColor
        : Color(_getActivePresetColor());

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
          'Audio Settings',
          style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5),
        ),
        actions: [
          if (_selectedPreset == 'Custom')
            IconButton(
              icon: Icon(Icons.save, color: widget.accentColor),
              tooltip: 'Save Preset',
              onPressed: _showSavePresetDialog,
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: widget.accentColor),
            tooltip: 'Reset All',
            onPressed: _resetAll,
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
                  // Headphones hint
                  Row(
                    children: [
                      Icon(Icons.headphones, color: subText, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Put in earphones before adjusting sound effects',
                          style: TextStyle(color: subText, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ✅ SECTION: ENHANCE SOUND
                  _buildSectionHeader('ENHANCE SOUND', subText),
                  const SizedBox(height: 12),

                  _buildIntensitySlider(
                    label: 'Bass Intensity',
                    icon: Icons.graphic_eq,
                    value: _bassLevel,
                    isDark: isDark,
                    color: widget.accentColor,
                    onChanged: (value) {
                      setState(() => _bassLevel = value);
                      _applyBassImmersive();
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildIntensitySlider(
                    label: 'Immersive Intensity',
                    icon: Icons.surround_sound,
                    value: _immersiveLevel,
                    isDark: isDark,
                    color: widget.accentColor,
                    onChanged: (value) {
                      setState(() => _immersiveLevel = value);
                      _applyBassImmersive();
                    },
                  ),
                  const SizedBox(height: 30),

                  // ✅ SECTION: EQUALIZER
                  _buildSectionHeader('EQUALIZER', subText),
                  const SizedBox(height: 12),

                  // Frequency Curve
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [card, card.withOpacity(0.6)]
                            : [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                          color: activeColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_getActivePresetEmoji(),
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text(_selectedPreset,
                                      style: TextStyle(
                                          color: activeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.graphic_eq, color: subText, size: 16),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
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

                  const SizedBox(height: 24),

                  // Presets
                  Row(
                    children: [
                      Text('PRESETS',
                          style: TextStyle(
                              color: subText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.8)),
                      const Spacer(),
                      Text(
                          '${_builtinPresets.length + _customPresets.length} available',
                          style: TextStyle(color: subText, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _builtinPresets.length + _customPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final isCustom = i >= _builtinPresets.length;
                        final p = isCustom
                            ? _customPresets[i - _builtinPresets.length]
                            : _builtinPresets[i];
                        final isActive = _selectedPreset == p['name'];
                        final pColor = Color(p['color'] as int);
                        return GestureDetector(
                          onTap: () => isCustom
                              ? _applyCustomPreset(p)
                              : _applyPreset(p['name'] as String),
                          onLongPress: isCustom
                              ? () => _deleteCustomPreset(
                                  i - _builtinPresets.length)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(colors: [
                                      pColor,
                                      pColor.withOpacity(0.7)
                                    ])
                                  : null,
                              color: isActive ? null : card,
                              borderRadius: BorderRadius.circular(21),
                              border: isActive
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                          color: pColor.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(p['emoji'] as String,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(p['name'] as String,
                                    style: TextStyle(
                                        color:
                                            isActive ? Colors.white : textColor,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bands
                  Row(
                    children: [
                      Text('BANDS',
                          style: TextStyle(
                              color: subText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.8)),
                      const Spacer(),
                      Text('${_minLevel ~/ 100} dB  ↔  +${_maxLevel ~/ 100} dB',
                          style: TextStyle(color: subText, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Column(
                            children: [
                              Text('+15',
                                  style: TextStyle(
                                      color: subText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 28),
                              Text('0',
                                  style: TextStyle(
                                      color: subText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 28),
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
                              final freq = i < _centerFreqs.length
                                  ? _centerFreqs[i]
                                  : 0;
                              return _buildBand(i, _formatFreq(freq),
                                  activeColor, isDark, card);
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ SECTION: REVERB
                  Row(
                    children: [
                      Text('REVERB',
                          style: TextStyle(
                              color: subText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.8)),
                      const Spacer(),
                      if (_reverbEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _reverbPresets.firstWhere(
                                    (r) => r['name'] == _selectedReverb,
                                    orElse: () => _reverbPresets[0])['label']
                                as String,
                            style: TextStyle(
                                color: widget.accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      GestureDetector(
                        onTap: _showReverbMenu,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.more_vert,
                              color: widget.accentColor, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _showReverbMenu,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _reverbEnabled
                                ? widget.accentColor.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _reverbEnabled
                                  ? widget.accentColor.withOpacity(0.15)
                                  : (isDark
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _reverbPresets.firstWhere(
                                      (r) => r['name'] == _selectedReverb,
                                      orElse: () => _reverbPresets[0])['emoji']
                                  as String,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _reverbEnabled ? 'Reverb Active' : 'Reverb Off',
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _reverbEnabled
                                      ? _reverbPresets.firstWhere(
                                              (r) =>
                                                  r['name'] == _selectedReverb,
                                              orElse: () =>
                                                  _reverbPresets[0])['label']
                                          as String
                                      : 'Tap to choose reverb effect',
                                  style:
                                      TextStyle(color: subText, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: subText, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ SECTION: LOUDNESS
                  _buildSectionHeader('LOUDNESS', subText),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volume_up,
                                color: _loudnessEnabled
                                    ? widget.accentColor
                                    : subText,
                                size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Loudness Enhancer',
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  Text('Boost quiet audio',
                                      style: TextStyle(
                                          color: subText, fontSize: 11)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _loudnessEnabled,
                              onChanged: _onLoudnessToggle,
                              activeColor: widget.accentColor,
                            ),
                          ],
                        ),
                        if (_loudnessEnabled) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                  '+${(_loudnessGain / 100).toStringAsFixed(0)} dB',
                                  style: TextStyle(
                                      color: widget.accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: _loudnessGain.toDouble(),
                                  min: 0,
                                  max: 1500,
                                  divisions: 15,
                                  activeColor: widget.accentColor,
                                  onChanged: (v) =>
                                      _onLoudnessGainChanged(v.round()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Reset Button
                  Center(
                    child: GestureDetector(
                      onTap: _resetAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          gradient:
                              LinearGradient(colors: widget.gradientColors),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                                color: widget.gradientColors[0]
                                    .withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restore, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Reset All',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
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

  void _showReverbMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = widget.isDarkTheme;
        final card = isDark ? const Color(0xFF181820) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subText = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

        return Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: subText,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, color: widget.accentColor, size: 22),
                      const SizedBox(width: 12),
                      Text('Reverb Effect',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Divider(color: subText.withOpacity(0.2), height: 1),
                ..._reverbPresets.map((r) {
                  final isActive = _selectedReverb == r['name'];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.accentColor.withOpacity(0.15)
                            : (isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(r['emoji'] as String,
                          style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(r['label'] as String,
                        style: TextStyle(
                            color: isActive ? widget.accentColor : textColor,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.w500)),
                    trailing: isActive
                        ? Icon(Icons.check_circle,
                            color: widget.accentColor, size: 22)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _onReverbChanged(r['name'] as String);
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSavePresetDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDarkTheme ? const Color(0xFF181820) : Colors.white,
        title: Text('Save Preset',
            style: TextStyle(
                color: widget.isDarkTheme ? Colors.white : Colors.black87)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(
              color: widget.isDarkTheme ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'e.g. My Bass',
            hintStyle: TextStyle(
                color: widget.isDarkTheme
                    ? Colors.grey.shade500
                    : Colors.grey.shade600),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final newPreset = {
                'name': name,
                'levels': List.from(_bandLevels),
                'emoji': '⭐',
                'color': widget.accentColor.value,
              };
              setState(() => _customPresets.add(newPreset));
              await _saveCustomPresets();
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ "$name" saved!'),
                  backgroundColor: widget.accentColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomPreset(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDarkTheme ? const Color(0xFF181820) : Colors.white,
        title: Text('Delete Preset?',
            style: TextStyle(
                color: widget.isDarkTheme ? Colors.white : Colors.black87)),
        content: Text('Delete "${_customPresets[index]['name']}"?',
            style: TextStyle(
                color: widget.isDarkTheme
                    ? Colors.grey.shade500
                    : Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              setState(() => _customPresets.removeAt(index));
              await _saveCustomPresets();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _isCustomSelected() =>
      _customPresets.any((p) => p['name'] == _selectedPreset);

  int _getActivePresetColor() {
    final builtin = _builtinPresets.firstWhere(
        (p) => p['name'] == _selectedPreset,
        orElse: () => _builtinPresets[0]);
    return builtin['color'] as int;
  }

  String _getActivePresetEmoji() {
    if (_isCustomSelected()) return '⭐';
    final builtin = _builtinPresets.firstWhere(
        (p) => p['name'] == _selectedPreset,
        orElse: () => _builtinPresets[0]);
    return builtin['emoji'] as String;
  }

  Widget _buildSectionHeader(String title, Color subText) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                color: subText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8)),
        const SizedBox(width: 10),
        Expanded(
            child: Container(height: 1, color: subText.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildIntensitySlider({
    required String label,
    required IconData icon,
    required double value,
    required bool isDark,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181820) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: color,
              inactiveTrackColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              thumbColor: color,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayColor: color.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBand(
      int index, String label, Color activeColor, bool isDark, Color card) {
    final level = _bandLevels[index];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              level == 0
                  ? '0'
                  : '${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',
              style: TextStyle(
                color: level != 0 ? activeColor : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: activeColor,
                  inactiveTrackColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  thumbColor: activeColor,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9, elevation: 4),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
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

// Frequency Curve Painter
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
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, size.height * 0.1),
        Offset(size.width, size.height * 0.1), gridPaint);
    final dashPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, size.height * 0.5),
          Offset(x + 4, size.height * 0.5), dashPaint);
    }
    canvas.drawLine(Offset(0, size.height * 0.9),
        Offset(size.width, size.height * 0.9), gridPaint);

    if (bandLevels.isEmpty) return;

    final points = <Offset>[];
    for (int i = 0; i < bandLevels.length; i++) {
      final x = (i / (bandLevels.length - 1)) * size.width;
      final levelNorm = bandLevels[i] / maxLevel;
      final y = size.height * (0.5 - levelNorm * 0.4);
      points.add(Offset(x, y));
    }

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
            activeColor.withOpacity(0.05)
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 4.5, Paint()..color = activeColor);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyCurvePainter oldDelegate) {
    return oldDelegate.bandLevels != bandLevels ||
        oldDelegate.activeColor != activeColor;
  }
}
