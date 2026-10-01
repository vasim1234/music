import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  static const _bassChannel = MethodChannel('com.example.music_player/bass_boost');
  List<MediaItem> _queue = [];
  int _currentIndex = 0;

  MyAudioHandler() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));

    mediaItem.add(null);

    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _getProcessingState(state.processingState),
      ));
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });

    // ✅ AudioSession ID — native pe bhejo
    _player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _bassChannel.invokeMethod('setAudioSessionId', {'sessionId': sessionId});
        debugPrint('🎵 AudioSession ID sent to native: $sessionId');
      }
    });

    // ✅ NAYA: Playback event listener — har track change pe saved settings apply
    _player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.ready) {
        _applySavedAudioSettings();
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('Playback event error: $e');
    });
  }

  // ✅ NAYA: Saved settings auto-apply karo
  Future<void> _applySavedAudioSettings() async {
    try {
      // Thoda delay — AudioSession ko initialize hone do
      await Future.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();

      // Bass Boost
      final bassLevel = prefs.getDouble('bass_level') ?? 0.3;
      final immersiveLevel = prefs.getDouble('immersive_level') ?? 0.3;

      // Equalizer
      final eqPreset = prefs.getString('eq_preset') ?? 'Flat';
      final eqBands = prefs.getStringList('eq_bands');

      // Reverb
      final reverbEnabled = prefs.getBool('reverb_enabled') ?? false;
      final reverbPreset = prefs.getString('reverb_preset') ?? 'None';

      // Loudness
      final loudnessEnabled = prefs.getBool('loudness_enabled') ?? false;
      final loudnessGain = prefs.getInt('loudness_gain') ?? 500;

      // Apply Bass + Immersive
      if (bassLevel > 0) {
        await setBassBoost(true, (bassLevel * 1000).round());
      }
      if (immersiveLevel > 0) {
        await setImmersive(true, (immersiveLevel * 1000).round());
      }

      // Apply EQ preset
      if (eqPreset != 'Flat' && eqPreset != 'Custom') {
        await setEqualizerPreset(eqPreset);
      }

      // Apply EQ bands
      if (eqBands != null && eqBands.isNotEmpty) {
        for (int i = 0; i < eqBands.length; i++) {
          final level = int.tryParse(eqBands[i]) ?? 0;
          await setEqualizerBand(i, level);
        }
      }

      // Apply Reverb
      if (reverbEnabled && reverbPreset != 'None') {
        await setReverb(true, reverbPreset);
      }

      // Apply Loudness
      if (loudnessEnabled) {
        await setLoudness(true, loudnessGain);
      }

      debugPrint('✅ Saved audio settings applied on new track');
    } catch (e) {
      debugPrint('❌ Apply saved settings error: $e');
    }
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() {
    debugPrint('▶️ play() called from notification');
    return _player.play();
  }

  @override
  Future<void> pause() {
    debugPrint('⏸️ pause() called from notification');
    return _player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('⏹️ stop() called');
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) {
    debugPrint('⏩ seek() called: $position');
    return _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('⏭️ skipToNext() called');
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await _playCurrent();
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('⏮️ skipToPrevious() called');
    if (_queue.isEmpty) return;
    _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : _queue.length - 1;
    await _playCurrent();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    debugPrint('⏯️ skipToQueueItem() called: $index');
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrent();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    debugPrint('🔊 Volume set to: $volume');
  }

  Future<void> setBassBoost(bool enabled, int strength) async {
    try {
      await _bassChannel.invokeMethod('setBassBoost', {
        'enabled': enabled,
        'strength': strength,
      });
      debugPrint('🎸 Bass Boost: $enabled @ $strength');
    } catch (e) {
      debugPrint('❌ setBassBoost error: $e');
    }
  }

  Future<void> setImmersive(bool enabled, int strength) async {
    try {
      await _bassChannel.invokeMethod('setImmersive', {
        'enabled': enabled,
        'strength': strength,
      });
      debugPrint('🌊 Immersive: $enabled @ $strength');
    } catch (e) {
      debugPrint('❌ setImmersive error: $e');
    }
  }

  Future<void> setEqualizerPreset(String presetName) async {
    try {
      await _bassChannel.invokeMethod('setEqualizerPreset', {
        'preset': presetName,
      });
      debugPrint('🎛️ EQ Preset: $presetName');
    } catch (e) {
      debugPrint('❌ setEqualizerPreset error: $e');
    }
  }

  Future<void> setEqualizerBand(int bandIndex, int levelMb) async {
    try {
      await _bassChannel.invokeMethod('setEqualizerBand', {
        'bandIndex': bandIndex,
        'levelMb': levelMb,
      });
      debugPrint('🎛️ EQ Band $bandIndex: $levelMb mB');
    } catch (e) {
      debugPrint('❌ setEqualizerBand error: $e');
    }
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    try {
      await _bassChannel.invokeMethod('setEqualizerEnabled', {
        'enabled': enabled,
      });
      debugPrint('🎛️ EQ Enabled: $enabled');
    } catch (e) {
      debugPrint('❌ setEqualizerEnabled error: $e');
    }
  }

  Future<Map<String, dynamic>> getEqualizerInfo() async {
    try {
      final result = await _bassChannel.invokeMethod('getEqualizerInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('❌ getEqualizerInfo error: $e');
      return {
        'numBands': 0,
        'minLevel': -1500,
        'maxLevel': 1500,
        'centerFreqs': <int>[],
      };
    }
  }

  Future<void> setReverb(bool enabled, String presetName) async {
    try {
      await _bassChannel.invokeMethod('setReverb', {
        'enabled': enabled,
        'preset': presetName,
      });
      debugPrint('🏛️ Reverb: $enabled @ $presetName');
    } catch (e) {
      debugPrint('❌ setReverb error: $e');
    }
  }

  Future<void> setLoudness(bool enabled, int gainMb) async {
    try {
      await _bassChannel.invokeMethod('setLoudness', {
        'enabled': enabled,
        'gainMb': gainMb,
      });
      debugPrint('📢 Loudness: $enabled @ $gainMb mB');
    } catch (e) {
      debugPrint('❌ setLoudness error: $e');
    }
  }

  Future<void> _playCurrent() async {
    if (_queue.isEmpty) return;
    final item = _queue[_currentIndex];
    mediaItem.add(item);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.file(item.id)));
      _player.play();
      debugPrint('✅ Playing: ${item.title}');
    } catch (e) {
      debugPrint('❌ Error playing: $e');
    }
  }

  Future<void> setQueue(List<String> songPaths, int index) async {
    _queue = [];
    for (var path in songPaths) {
      _queue.add(MediaItem(
        id: path,
        title: _getSongName(path),
        artist: 'Bhai Bhai Music',
        album: 'Local Audio',
      ));
    }
    _currentIndex = index;
    await updateQueue(_queue);
    await _playCurrent();
  }

  String _getSongName(String path) {
    String name = path.split('/').last;
    name = name.replaceAll(
        RegExp(r'\.(mp3|m4a|wav|aac|ogg|flac)$', caseSensitive: false), '');
    return name.replaceAll('_', ' ').trim();
  }

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
}

MyAudioHandler? audioHandler;

Future<void> initAudioService() async {
  debugPrint('🔄 initAudioService START');
  try {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.bhaibhai.music.channel.audio',
        androidNotificationChannelName: 'Bhai Bhai Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: false,
      ),
    );
    debugPrint('✅ audioHandler SET: ${audioHandler != null}');
  } catch (e) {
    debugPrint('❌ initAudioService ERROR: $e');
  }
}
