import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      setState(() => isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickAndPlay() async {
    String? filePath = await FilePicker.platform.getPath();
    if (filePath != null) {
      await _player.play(DeviceFileSource(filePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select a song to play',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickAndPlay,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_position > Duration.zero) ...[
              Text(
                'Now Playing',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('${_position.inSeconds}s / ${_duration.inSeconds}s'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      isPlaying ? _player.pause() : _player.resume();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () {
                      _player.stop();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
