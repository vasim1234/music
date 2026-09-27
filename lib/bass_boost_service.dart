import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class BassBoostService {
  static const _channel = MethodChannel('com.example.music_player/bass_boost');
  final AudioPlayer _player;

  BassBoostService(this._player) {
    // just_audio se AudioSession ID milne par native ko bhejo
    _player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _channel.invokeMethod('setAudioSessionId', {'sessionId': sessionId});
      }
    });
  }

  Future<void> setBassBoost(bool enabled, int strength) async {
    await _channel.invokeMethod('setBassBoost', {
      'enabled': enabled,
      'strength': strength,
    });
  }

  Future<void> setImmersive(bool enabled, int strength) async {
    await _channel.invokeMethod('setImmersive', {
      'enabled': enabled,
      'strength': strength,
    });
  }

  Future<Map<String, dynamic>> getBassBoost() async {
    final result = await _channel.invokeMethod('getBassBoost');
    return Map<String, dynamic>.from(result);
  }
}
