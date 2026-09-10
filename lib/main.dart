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
      title: 'Bhai Bhai Music',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
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
  List<File> _filteredSongs = [];
  List<String> _favorites = [];
  List<Map<String, dynamic>> _playlists = [];
  File? _currentSong;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = -1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      setState(() => isPlaying = state == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) => _playNext());
    _checkPermission();
    _loadSavedData();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedPaths = prefs.getStringList('saved_songs');
    List<String>? favs = prefs.getStringList('favorites');
    List<String>? playlists = prefs.getStringList('playlists');

    if (savedPaths != null) {
      List<File> songs = savedPaths
          .map((path) => File(path))
          .where((f) => f.existsSync())
          .toList();
      setState(() {
        _songs = songs;
        _filteredSongs = songs;
      });
    }

    if (favs != null) {
      setState(() => _favorites = favs);
    }

    if (playlists != null) {
      setState(() {
        _playlists = playlists.map((p) {
          List<String> parts = p.split('|||');
          return {
            'name': parts[0],
            'songs': parts.length > 1
                ? parts[1].split(',').where((s) => s.isNotEmpty).toList()
                : <String>[],
          };
        }).toList();
      });
    }
  }

  Future<void> _saveSongs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> paths = _songs.map((f) => f.path).toList();
    await prefs.setStringList('saved_songs', paths);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> playlistData = _playlists
        .map((p) => '${p['name']}|||${(p['songs'] as List<String>).join(',')}')
        .toList();
    await prefs.setStringList('playlists', playlistData);
  }

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
          _filteredSongs = _songs;
        });

        await _saveSongs();
        _showSnackBar('✅ ${pickedSongs.length} songs added!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('⚠️ Error: $e', Colors.red);
    }
  }

  Future<void> _scanDefaultFolder() async {
    try {
      List<File> allSongs = [];
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
                if (path.endsWith('.mp3') ||
                    path.endsWith('.m4a') ||
                    path.endsWith('.wav') ||
                    path.endsWith('.aac') ||
                    path.endsWith('.ogg') ||
                    path.endsWith('.flac')) {
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
        _filteredSongs = _songs;
      });

      await _saveSongs();
      _showSnackBar('✅ ${allSongs.length} songs found!', Colors.green);
    } catch (e) {
      _showSnackBar('⚠️ Error: $e', Colors.red);
    }
  }

  Future<void> _playSong(File song, int index) async {
    setState(() {
      _currentSong = song;
      _currentIndex = index;
    });
    await _player.play(DeviceFileSource(song.path));
  }

  void _togglePlay() {
    isPlaying ? _player.pause() : _player.resume();
  }

  void _playNext() {
    if (_filteredSongs.isEmpty) return;
    int nextIndex = isShuffle
        ? (DateTime.now().millisecondsSinceEpoch % _filteredSongs.length)
        : (_currentIndex + 1) % _filteredSongs.length;
    _playSong(_filteredSongs[nextIndex], nextIndex);
  }

  void _playPrevious() {
    if (_filteredSongs.isEmpty) return;
    int prevIndex =
        _currentIndex > 0 ? _currentIndex - 1 : _filteredSongs.length - 1;
    _playSong(_filteredSongs[prevIndex], prevIndex);
  }

  // ✅ DELETE SONG
  void _deleteSong(int index) {
    setState(() {
      if (_songs[index] == _currentSong) {
        _player.stop();
        _currentSong = null;
        _currentIndex = -1;
      }
      _songs.removeAt(index);
      _filteredSongs = _songs;
    });
    _saveSongs();
    _showSnackBar('🗑️ Song deleted', Colors.red);
  }

  // ✅ TOGGLE FAVORITE
  void _toggleFavorite(File song) {
    setState(() {
      if (_favorites.contains(song.path)) {
        _favorites.remove(song.path);
        _showSnackBar('💔 Removed from Favorites', Colors.orange);
      } else {
        _favorites.add(song.path);
        _showSnackBar('❤️ Added to Favorites', Colors.pink);
      }
    });
    _saveFavorites();
  }

  // ✅ ADD TO PLAYLIST
  void _addToPlaylist(File song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '📁 Add to Playlist',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Existing Playlists
                if (_playlists.isNotEmpty)
                  ..._playlists.map((playlist) {
                    bool isIn =
                        (playlist['songs'] as List<String>).contains(song.path);
                    return ListTile(
                      leading: Icon(
                        isIn ? Icons.check_circle : Icons.playlist_add,
                        color: isIn ? Colors.green : Colors.deepPurpleAccent,
                      ),
                      title: Text(
                        playlist['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${(playlist['songs'] as List<String>).length} songs',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () {
                        setState(() {
                          if (isIn) {
                            (playlist['songs'] as List<String>)
                                .remove(song.path);
                          } else {
                            (playlist['songs'] as List<String>).add(song.path);
                          }
                        });
                        _savePlaylists();
                        Navigator.pop(context);
                        _showSnackBar(
                          isIn
                              ? 'Removed from ${playlist['name']}'
                              : 'Added to ${playlist['name']}',
                          isIn ? Colors.red : Colors.green,
                        );
                      },
                    );
                  }).toList(),

                const Divider(color: Colors.grey),

                // Create New Playlist
                ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: Colors.greenAccent),
                  title: const Text(
                    '➕ Create New Playlist',
                    style: TextStyle(
                        color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewPlaylist(song);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  // ✅ CREATE NEW PLAYLIST
  void _createNewPlaylist(File song) {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '➕ New Playlist',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter playlist name',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon:
                  const Icon(Icons.playlist_play, color: Colors.deepPurpleAccent),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: Colors.deepPurpleAccent, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _playlists.add({
                      'name': nameController.text.trim(),
                      'songs': [song.path],
                    });
                  });
                  _savePlaylists();
                  Navigator.pop(context);
                  _showSnackBar(
                    '✅ Playlist "${nameController.text}" created!',
                    Colors.green,
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // ✅ LONG PRESS BOTTOM SHEET
  void _showSongOptions(File song, int index) {
    bool isFav = _favorites.contains(song.path);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Song Info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFFD946EF)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.music_note,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getSongName(song.path),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Local Audio',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.grey, height: 1),

                // Options
                _buildOptionTile(
                  icon: isFav ? Icons.favorite : Icons.favorite_border,
                  iconColor: isFav ? Colors.pink : Colors.pinkAccent,
                  title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFavorite(song);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.playlist_add,
                  iconColor: Colors.deepPurpleAccent,
                  title: 'Add to Playlist',
                  onTap: () {
                    Navigator.pop(context);
                    _addToPlaylist(song);
                  },
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  iconColor: Colors.redAccent,
                  title: 'Delete Song',
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(index);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }

  // ✅ CONFIRM DELETE
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🗑️ Delete Song?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${getSongName(_songs[index].path)}"?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteSong(index);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _songs;
      } else {
        _filteredSongs = _songs
            .where((f) => f.path.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  String getSongName(String path) {
    String name = path.split('/').last;
    name = name.replaceAll(
        RegExp(r'\.(mp3|m4a|wav|aac|ogg|flac)$', caseSensitive: false), '');
    return name.replaceAll('_', ' ').trim();
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFD946EF)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bhai Bhai Music',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Feel The Rhythm',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSongs,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickSongs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C9A7), Color(0xFF00B4D8)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C9A7).withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.library_music,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pick Songs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _scanDefaultFolder,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFD946EF)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Scan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SONG COUNT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.queue_music,
                        color: Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredSongs.length} songs',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    const Text(
                      'Long press for options',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // SONG LIST
              Expanded(
                child: _filteredSongs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          return _buildSongTile(_filteredSongs[index], index);
                        },
                      ),
              ),

              // MINI PLAYER
              if (_currentSong != null) _buildMiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_off, size: 80, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          const Text(
            'No songs found!',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Pick Songs" or "Scan" to add songs',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(File song, int index) {
    bool isSelected = _currentSong == song;
    bool isFav = _favorites.contains(song.path);

    return GestureDetector(
      // ✅ TAP - Play Song
      onTap: () => _playSong(song, index),
      // ✅ LONG PRESS - Show Options Menu
      onLongPress: () => _showSongOptions(song, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFD946EF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Album Art
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Colors.white24, Colors.white10])
                    : LinearGradient(
                        colors: [Colors.grey.shade700, Colors.grey.shade800],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected && isPlaying ? Icons.graphic_eq : Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getSongName(song.path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isFav) ...[
                        const Icon(Icons.favorite,
                            color: Colors.pinkAccent, size: 12),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isSelected && isPlaying ? 'Now Playing' : 'Local Audio',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ Play/Pause button (agar selected hai toh)
            if (isSelected)
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: _togglePlay,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getSongName(_currentSong!.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Now Playing',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: _togglePlay,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _position.inSeconds.toDouble().clamp(
                        0.0,
                        _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1.0,
                      ),
                  max: _duration.inSeconds.toDouble() > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) async {
                    await _player.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatTime(_position),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      formatTime(_duration),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  isShuffle ? Icons.shuffle : Icons.shuffle_outlined,
                  color: isShuffle ? Colors.white : Colors.white70,
                  size: 24,
                ),
                onPressed: () => setState(() => isShuffle = !isShuffle),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous,
                    color: Colors.white, size: 35),
                onPressed: _playPrevious,
              ),
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: _togglePlay,
              ),
              IconButton(
                icon:
                    const Icon(Icons.skip_next, color: Colors.white, size: 35),
                onPressed: _playNext,
              ),
              IconButton(
                icon: Icon(
                  isRepeat ? Icons.repeat_one : Icons.repeat,
                  color: isRepeat ? Colors.white : Colors.white70,
                  size: 24,
                ),
                onPressed: () => setState(() => isRepeat = !isRepeat),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
