import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      setState(() => isPlaying = state == PlayerState.playing);
    });
    _checkPermission();
    _loadSavedSongs();
  }

  // ✅ PERMISSION CHECK
  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      setState(() {
        _hasPermission = true;
      });
    }
  }

  // ✅ LOAD SAVED SONGS
  Future<void> _loadSavedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedPaths = prefs.getStringList('saved_songs');
    if (savedPaths != null) {
      List<File> songs = savedPaths
          .map((path) => File(path))
          .where((f) => f.existsSync())
          .toList();
      setState(() {
        _songs = songs;
      });
    }
  }

  // ✅ SAVE SONGS
  Future<void> _saveSongs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> paths = _songs.map((f) => f.path).toList();
    await prefs.setStringList('saved_songs', paths);
  }

  // ✅ PICK SONGS - MAIN FEATURE
  Future<void> _pickSongs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: 'Select Songs',
      );

      if (result != null) {
        List<File> pickedSongs = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        setState(() {
          for (var song in pickedSongs) {
            if (!_songs.any((f) => f.path == song.path)) {
              _songs.add(song);
            }
          }
        });

        await _saveSongs();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${pickedSongs.length} songs added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    }
  }

  // ✅ SCAN DEFAULT MUSIC FOLDER
  Future<void> _scanDefaultFolder() async {
    try {
      List<File> allSongs = [];
      
      // Common music folders
      List<String> folders = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/snaptube/download/SnapTube Audio',
        '/storage/emulated/0/snaptube',
      ];

      for (var folderPath in folders) {
        Directory dir = Directory(folderPath);
        if (dir.existsSync()) {
          try {
            List<FileSystemEntity> entities = dir.listSync(recursive: true);
            for (var entity in entities) {
              if (entity is File) {
                String path = entity.path.toLowerCase();
                if (path.endsWith('.mp3') || path.endsWith('.m4a') || 
                    path.endsWith('.wav') || path.endsWith('.aac') ||
                    path.endsWith('.ogg') || path.endsWith('.flac')) {
                  allSongs.add(entity);
                }
              }
            }
          } catch (e) {
            print('⚠️ Error scanning $folderPath: $e');
          }
        }
      }

      setState(() {
        for (var song in allSongs) {
          if (!_songs.any((f) => f.path == song.path)) {
            _songs.add(song);
          }
        }
      });

      await _saveSongs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${allSongs.length} songs found!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('⚠️ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    }
  }

  // ✅ PLAY SONG
  Future<void> _playSong(File song) async {
    _currentSong = song;
    await _player.play(DeviceFileSource(song.path));
    setState(() {});
  }

  void _togglePlay() {
    isPlaying ? _player.pause() : _player.resume();
  }

  // ✅ DELETE SONG
  void _deleteSong(int index) {
    setState(() {
      _songs.removeAt(index);
    });
    _saveSongs();
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
          // ✅ BUTTONS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickSongs,
                    icon: const Icon(Icons.library_music),
                    label: const Text('🎵 Pick Songs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanDefaultFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('📁 Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ SONG COUNT
          Text(
            '${_songs.length} songs found',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          
          const Divider(),
          
          // ✅ SONGS LIST
          Expanded(
            child: _songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No songs found!', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Tap "Pick Songs" to add', style: TextStyle(color: Colors.grey)),
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
                          song.path.split('/').last.replaceAll(RegExp(r'\.[^.]*$'), ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.deepPurple : Colors.black87,
                          ),
                        ),
                        subtitle: const Text('Local Audio', style: TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              IconButton(
                                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.deepPurple),
                                onPressed: _togglePlay,
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteSong(index),
                            ),
                          ],
                        ),
                        onTap: () => _playSong(song),
                      );
                    },
                  ),
          ),
          
          // ✅ MINI PLAYER
          if (_currentSong != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
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
                            Text(
                              _currentSong!.path.split('/').last.replaceAll(RegExp(r'\.[^.]*$'), ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text('Now Playing', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.deepPurple, size: 40),
                        onPressed: _togglePlay,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop_circle_outlined, color: Colors.deepPurple, size: 40),
                        onPressed: () {
                          _player.stop();
                          setState(() {
                            _currentSong = null;
                          });
                        },
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
