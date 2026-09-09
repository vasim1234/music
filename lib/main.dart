import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
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
    _checkPermissionAndLoad();
  }

  // ✅ PERMISSION KA DUMDAAR FUNCTION
  Future<void> _checkPermissionAndLoad() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        // Android 11+
        final status = await Permission.manageExternalStorage.status;
        if (status.isPermanentlyDenied || status.isDenied) {
          _showPermissionDialog();
          return;
        }
        if (status.isGranted) {
          _loadDefaultMusic();
        }
      } else {
        // Android 10 ya usse purana
        final status = await Permission.storage.status;
        if (status.isDenied) await Permission.storage.request();
        if (status.isGranted) _loadDefaultMusic();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Permission Needed'),
        content: const Text(
          'Music app needs "All files access" to scan your songs.\n\n'
          '👉 Tap "Open Settings"\n'
          '👉 Go to "Permissions"\n'
          '👉 Enable "Files and Media"\n'
          '👉 Come back and restart the app.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDefaultMusic() async {
    try {
      final musicDir = Directory('/storage/emulated/0/Music');
      if (musicDir.existsSync()) {
        final files = musicDir.listSync(recursive: true).whereType<File>().where((f) => f.path.toLowerCase().endsWith('.mp3')).toList();
        setState(() => _songs = files);
        if (files.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${files.length} songs found in Music folder!')),
          );
        }
      }
    } catch (e) {
      print('⚠️ Default load error: $e');
    }
  }

  Future<void> _pickFolder() async {
    try {
      String? path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        Directory dir = Directory(path);
        final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.toLowerCase().endsWith('.mp3')).toList();
        setState(() => _songs = files);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${files.length} songs found!')),
        );
      }
    } catch (e) {
      print('⚠️ Folder pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Error scanning folder. Please grant permission first.')),
      );
    }
  }

  Future<void> _playSong(File song) async {
    _currentSong = song;
    await _player.play(DeviceFileSource(song.path));
    setState(() {});
  }

  void _togglePlay() {
    isPlaying ? _player.pause() : _player.resume();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _checkPermissionAndLoad,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('📁 Select Folder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDefaultMusic,
                ),
              ],
            ),
          ),
          Text('${_songs.length} songs found', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Divider(),
          Expanded(
            child: _songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No songs found!', style: TextStyle(fontSize: 18)),
                        Text('Grant permission & select folder', style: TextStyle(color: Colors.grey)),
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
                          child: Icon(Icons.music_note, color: isSelected ? Colors.white : Colors.black54),
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
                                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.deepPurple),
                                onPressed: _togglePlay,
                              )
                            : null,
                        onTap: () => _playSong(song),
                      );
                    },
                  ),
          ),
          if (_currentSong != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                            Text(_currentSong!.path.split('/').last.replaceAll('.mp3', ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Local Audio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.deepPurple, size: 40),
                        onPressed: _togglePlay,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop_circle_outlined, color: Colors.deepPurple, size: 40),
                        onPressed: () { _player.stop(); setState(() {}); },
                      ),
                    ],
                  ),
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                    onChanged: (value) async => await _player.seek(Duration(seconds: value.toInt())),
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
