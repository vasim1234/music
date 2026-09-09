import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
  bool _isLoading = false;

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

  // ✅ PERMISSION CHECK
  Future<void> _checkPermissionAndLoad() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          _showPermissionDialog();
          return;
        }
        if (status.isGranted) {
          _loadAllSongs();
        }
      } else {
        final status = await Permission.storage.status;
        if (status.isDenied) await Permission.storage.request();
        if (status.isGranted) _loadAllSongs();
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
          'Music app needs "All files access" to scan songs.\n\n'
          '👉 Tap "Open Settings"\n👉 Go to "Permissions"\n👉 Enable "Files and Media"\n👉 Restart app'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); openAppSettings(); }, child: const Text('Open Settings')),
        ],
      ),
    );
  }

  // ✅ 3-IN-1 SONG SCANNER (Teeno Methods)
  Future<void> _loadAllSongs() async {
    setState(() => _isLoading = true);
    List<File> allSongs = [];

    // 🔴 METHOD 1: Default Music Folder
    try {
      final defaultMusic = Directory('/storage/emulated/0/Music');
      if (defaultMusic.existsSync()) {
        final files = defaultMusic.listSync(recursive: true).whereType<File>().where((f) => 
          f.path.toLowerCase().endsWith('.mp3') || 
          f.path.toLowerCase().endsWith('.m4a') ||
          f.path.toLowerCase().endsWith('.wav')
        ).toList();
        allSongs.addAll(files);
        print('✅ Method 1 (Music): ${files.length} songs found');
      }
    } catch (e) { print('Method 1 Error: $e'); }

    // 🔴 METHOD 2: Download Folder
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        final files = downloadDir.listSync(recursive: true).whereType<File>().where((f) => 
          f.path.toLowerCase().endsWith('.mp3') || 
          f.path.toLowerCase().endsWith('.m4a')
        ).toList();
        allSongs.addAll(files);
        print('✅ Method 2 (Download): ${files.length} songs found');
      }
    } catch (e) { print('Method 2 Error: $e'); }

    // 🔴 METHOD 3: SnapTube (Tumhari specific folder)
    try {
      final snapTubeDir = Directory('/storage/emulated/0/snaptube/download/SnapTube Audio');
      if (snapTubeDir.existsSync()) {
        final files = snapTubeDir.listSync(recursive: true).whereType<File>().where((f) => 
          f.path.toLowerCase().endsWith('.mp3') || 
          f.path.toLowerCase().endsWith('.m4a')
        ).toList();
        allSongs.addAll(files);
        print('✅ Method 3 (SnapTube): ${files.length} songs found');
      } else {
        // Agar SnapTube folder na mile toh "SnapTube" search karo
        final snapDir = Directory('/storage/emulated/0/snaptube');
        if (snapDir.existsSync()) {
          final files = snapDir.listSync(recursive: true).whereType<File>().where((f) => 
            f.path.toLowerCase().contains('snaptube') && 
            (f.path.toLowerCase().endsWith('.mp3') || f.path.toLowerCase().endsWith('.m4a'))
          ).toList();
          allSongs.addAll(files);
          print('✅ Method 3 (SnapTube search): ${files.length} songs found');
        }
      }
    } catch (e) { print('Method 3 Error: $e'); }

    // 🔴 METHOD 4: File Picker se manual select
    // (Ye already hai, par hum ise keep karte hain)

    // Remove duplicates
    final uniqueSongs = allSongs.toSet().toList();
    
    setState(() {
      _songs = uniqueSongs;
      _isLoading = false;
    });

    if (_songs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${_songs.length} songs found!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No songs found. Try selecting folder manually!'), backgroundColor: Colors.orange),
      );
    }
  }

  // ✅ MANUAL FOLDER SELECT
  Future<void> _pickFolder() async {
    try {
      String? path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        setState(() => _isLoading = true);
        Directory dir = Directory(path);
        final files = dir.listSync(recursive: true).whereType<File>().where((f) => 
          f.path.toLowerCase().endsWith('.mp3') || 
          f.path.toLowerCase().endsWith('.m4a') || 
          f.path.toLowerCase().endsWith('.wav')
        ).toList();
        setState(() {
          _songs = files;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${files.length} songs found!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('⚠️ Folder pick error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Error scanning folder. Try granting permission.')),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllSongs,
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
                if (_isLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          Text('${_songs.length} songs found', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Divider(),
          Expanded(
            child: _songs.isEmpty && !_isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No songs found!', style: TextStyle(fontSize: 18)),
                        Text('🔹 Grant "All files access" permission', style: TextStyle(color: Colors.grey)),
                        Text('🔹 Tap refresh button', style: TextStyle(color: Colors.grey)),
                        Text('🔹 Or select folder manually', style: TextStyle(color: Colors.grey)),
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
                            Text(
                              _currentSong!.path.split('/').last.replaceAll(RegExp(r'\.[^.]*$'), ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
