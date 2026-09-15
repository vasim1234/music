import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';  // ✅ Ye add karo

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
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
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
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
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await _playCurrent();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : _queue.length - 1;
    await _playCurrent();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_queue.isEmpty) return;
    final item = _queue[_currentIndex];
    mediaItem.add(item);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.file(item.id)));
      _player.play();
    } catch (e) {
      print('❌ Error playing: $e');
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
  print('🔄 initAudioService START');
  try {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.bhaibhai.music.channel.audio',
        androidNotificationChannelName: 'Bhai Bhai Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    print('✅ audioHandler SET: ${audioHandler != null}');
  } catch (e) {
    print('❌ initAudioService ERROR: $e');
  }
}
