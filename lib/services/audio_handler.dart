import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final ap.AudioPlayer _player = ap.AudioPlayer();
  List<MediaItem> _queue = [];
  int _currentIndex = 0;

  MyAudioHandler() {
    _player.onDurationChanged.listen((duration) {
      final item = mediaItem.value;
      if (item != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    _player.onPositionChanged.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    _player.onPlayerStateChanged.listen((state) {
      final playing = state == ap.PlayerState.playing;
      playbackState.add(playbackState.value.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
      ));
    });

    _player.onPlayerComplete.listen((_) {
      skipToNext();
    });
  }

  @override
  Future<void> play() => _player.resume();

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
    await _player.play(ap.DeviceFileSource(item.id));
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    _queue = queue;
    super.updateQueue(queue);
  }

  Future<void> setQueue(List<File> songs, int index) async {
    _queue = [];
    for (var song in songs) {
      _queue.add(MediaItem(
        id: song.path,
        title: _getSongName(song.path),
        artist: 'Bhai Bhai Music',
        album: 'Local Audio',
        duration: null,
      ));
    }
    _currentIndex = index;
    await _playCurrent();
  }

  String _getSongName(String path) {
    String name = path.split('/').last;
    name = name.replaceAll(
        RegExp(r'\.(mp3|m4a|wav|aac|ogg|flac)$', caseSensitive: false), '');
    return name.replaceAll('_', ' ').trim();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    super.setRepeatMode(repeatMode);
  }
}
