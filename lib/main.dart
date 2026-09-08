import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
      home: const MusicPlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<File> _songs = [];
  File? _currentSong;
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
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> _pickFolder() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      Directory dir = Directory(path);
      List<File> files = dir.listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.mp3'))
          .toList();
      setState(() {
        _songs = files;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${files.length} songs found!')),
      );
    }
  }

  Future<void> _playSong(File song) async {
    _currentSong = song;
    await _player.play(DeviceFileSource(song.path));
    setState(() {});
  }

  void _togglePlay() {
    if (isPlaying) {
      _player.pause();
    } else {
      _player.resume();
    }
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Music Player'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Select Folder Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _pickFolder,
              icon: const Icon(Icons.folder_open),
              label: Text('📁 Select Music Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          
          // Song Count
          Text(
            '${_songs.length} songs found',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          
          const Divider(),
          
          // Songs List
          Expanded(
            child: _songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No songs found!', style: TextStyle(fontSize: 18)),
                        Text('Select a folder to scan', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      File song = _songs[index];
                      bool isSelected = _currentSong == song;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                          child: Icon(
                            Icons.music_note,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                        title: Text(
                          song.path.split('/').last.replaceAll('.mp3', ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.deepPurple : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: _togglePlay,
                              )
                            : null,
                        onTap: () => _playSong(song),
                      );
                    },
                  ),
          ),
          
          // Mini Player
          if (_currentSong != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentSong!.path.split('/').last.replaceAll('.mp3', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text('Local Audio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.deepPurple,
                              size: 40,
                            ),
                            onPressed: _togglePlay,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle_outlined, color: Colors.deepPurple, size: 40),
                            onPressed: () {
                              _player.stop();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                    onChanged: (value) async {
                      await _player.seek(Duration(seconds: value.toInt()));
                    },
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple.shade100,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatTime(_position), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(formatTime(_duration), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
