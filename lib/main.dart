import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'album_art_service.dart';
import 'enhance_sound_screen.dart';

// ✅ 4 PREMIUM THEMES
class AppColors {
  // 🟢 THEME 0 - Midnight Emerald
  static const Color bg0 = Color(0xFF0B1310);
  static const Color card0 = Color(0xFF13221C);
  static const Color accent0 = Color(0xFF34D399);
  static const List<Color> gradient0 = [
    Color(0xFF059669),
    Color(0xFF34D399),
  ];

  // 🟡 THEME 1 - Obsidian Gold
  static const Color bg1 = Color(0xFF121212);
  static const Color card1 = Color(0xFF1E1E1E);
  static const Color accent1 = Color(0xFFD4AF37);
  static const List<Color> gradient1 = [
    Color(0xFFD4AF37),
    Color(0xFFC5A059),
  ];

  // 🔵 THEME 2 - Cosmic Indigo
  static const Color bg2 = Color(0xFF0A0E1A);
  static const Color card2 = Color(0xFF141B2D);
  static const Color accent2 = Color(0xFF06B6D4);
  static const List<Color> gradient2 = [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
  ];

  // 🟣 THEME 3 - Luxe Purple
  static const Color bg3 = Color(0xFF0F0F14);
  static const Color card3 = Color(0xFF181820);
  static const Color accent3 = Color(0xFF8B5CF6);
  static const List<Color> gradient3 = [
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
  ];
}

class AppTheme {
  static int themeIndex = 0;

  static Color get bg {
    switch (themeIndex) {
      case 0: return AppColors.bg0;
      case 1: return AppColors.bg1;
      case 2: return AppColors.bg2;
      case 3: return AppColors.bg3;
      default: return AppColors.bg0;
    }
  }

  static Color get card {
    switch (themeIndex) {
      case 0: return AppColors.card0;
      case 1: return AppColors.card1;
      case 2: return AppColors.card2;
      case 3: return AppColors.card3;
      default: return AppColors.card0;
    }
  }

  static Color get accent {
    switch (themeIndex) {
      case 0: return AppColors.accent0;
      case 1: return AppColors.accent1;
      case 2: return AppColors.accent2;
      case 3: return AppColors.accent3;
      default: return AppColors.accent0;
    }
  }

  static List<Color> get primaryGradient {
    switch (themeIndex) {
      case 0: return AppColors.gradient0;
      case 1: return AppColors.gradient1;
      case 2: return AppColors.gradient2;
      case 3: return AppColors.gradient3;
      default: return AppColors.gradient0;
    }
  }
}

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
        scaffoldBackgroundColor: AppTheme.bg,
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
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);
  List<File> _songs = [];
  List<File> _filteredSongs = [];
  List<String> _favorites = [];
  List<String> _recentSongs = [];
  List<Map<String, dynamic>> _playlists = [];
  String? _openedPlaylist;
  File? _currentSong;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  bool is3DOn = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = -1;
  int _selectedTab = 0;
  int _themeIndex = 0;
  double _bassLevel = 0.3;
  double _immersiveLevel = 0.3;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AlbumArtService.init();

    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      _isPlayingNotifier.value = playing;
      if (mounted) {
        setState(() => isPlaying = playing);
      }
    });
    _player.onPlayerComplete.listen((_) => _playNext());

    _checkPermission();
    _loadSavedData();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int theme = prefs.getInt('themeIndex') ?? 0;
    bool is3D = prefs.getBool('is3DOn') ?? false;
    setState(() {
      _themeIndex = theme;
      AppTheme.themeIndex = theme;
      is3DOn = is3D;
    });
  }

  Future<void> _toggleTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeIndex', index);
    setState(() {
      _themeIndex = index;
      AppTheme.themeIndex = index;
    });

    const names = [
      '🟢 Midnight Emerald',
      '🟡 Obsidian Gold',
      '🔵 Cosmic Indigo',
      '🟣 Luxe Purple',
    ];
    _showSnackBar('🎨 ${names[index]} applied', AppTheme.accent);
  }

  Future<void> _toggle3D() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      is3DOn = !is3DOn;
    });
    await prefs.setBool('is3DOn', is3DOn);

    if (is3DOn) {
      await _player.setVolume(0.85);
      await _player.setBalance(0.4);
      _showSnackBar('🎧 3D Audio ON', AppTheme.accent);
    } else {
      await _player.setVolume(1.0);
      await _player.setBalance(0.0);
      _showSnackBar('🔊 3D Audio OFF', Colors.grey);
    }
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
    List<String>? recent = prefs.getStringList('recent_songs');
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

    if (favs != null) setState(() => _favorites = favs);
    if (recent != null) setState(() => _recentSongs = recent);

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
    await prefs.setStringList('saved_songs', _songs.map((f) => f.path).toList());
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }

  Future<void> _saveRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_songs', _recentSongs);
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = _playlists
        .map((p) => '${p['name']}|||${(p['songs'] as List<String>).join(',')}')
        .toList();
    await prefs.setStringList('playlists', data);
  }

  Future<void> _pickSongs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
      );

      if (result != null) {
        List<File> picked = result.paths
            .where((p) => p != null)
            .map((p) => File(p!))
            .toList();

        setState(() {
          for (var song in picked) {
            if (!_songs.any((f) => f.path == song.path)) {
              _songs.add(song);
            }
          }
          _applyFilter();
        });

        await _saveSongs();
        _showSnackBar('✅ ${picked.length} songs added!', Colors.green);
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
            for (var entity in dir.listSync(recursive: true)) {
              if (entity is File) {
                String p = entity.path.toLowerCase();
                if (p.endsWith('.mp3') ||
                    p.endsWith('.m4a') ||
                    p.endsWith('.wav') ||
                    p.endsWith('.aac') ||
                    p.endsWith('.ogg') ||
                    p.endsWith('.flac')) {
                  allSongs.add(entity);
                }
              }
            }
          } catch (e) {}
        }
      }

      setState(() {
        for (var song in allSongs) {
          if (!_songs.any((f) => f.path == song.path)) _songs.add(song);
        }
        _applyFilter();
      });

      await _saveSongs();
      _showSnackBar('✅ ${allSongs.length} songs found!', Colors.green);
    } catch (e) {
      _showSnackBar('⚠️ Error: $e', Colors.red);
    }
  }

  Future<void> _playSong(File song, int index) async {
    if (_currentSong == song) {
      _togglePlay();
      return;
    }

    setState(() {
      _currentSong = song;
      _currentIndex = index;
      isPlaying = true;
    });
    _isPlayingNotifier.value = true;

    if (!_recentSongs.contains(song.path)) {
      _recentSongs.insert(0, song.path);
      if (_recentSongs.length > 20) _recentSongs.removeLast();
      await _saveRecent();
    }

    await _player.play(DeviceFileSource(song.path));

    if (is3DOn) {
      await _player.setVolume(0.85);
      await _player.setBalance(0.4);
    } else {
      await _player.setVolume(1.0);
      await _player.setBalance(0.0);
    }
  }

  Future<void> _togglePlay() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  void _playNext() {
    if (_filteredSongs.isEmpty) return;
    int next = isShuffle
        ? (DateTime.now().millisecondsSinceEpoch % _filteredSongs.length)
        : (_currentIndex + 1) % _filteredSongs.length;
    _playSong(_filteredSongs[next], next);
  }

  void _playPrevious() {
    if (_filteredSongs.isEmpty) return;
    int prev = _currentIndex > 0 ? _currentIndex - 1 : _filteredSongs.length - 1;
    _playSong(_filteredSongs[prev], prev);
  }

  void _applyFilter() {
    List<File> baseList = [];

    if (_selectedTab == 0) {
      baseList = _songs;
    } else if (_selectedTab == 1) {
      baseList = _songs.where((f) => _favorites.contains(f.path)).toList();
    } else if (_selectedTab == 2) {
      baseList = _recentSongs
          .map((path) => File(path))
          .where((f) => f.existsSync())
          .toList();
    } else if (_selectedTab == 3 && _openedPlaylist != null) {
      var playlist = _playlists.firstWhere(
        (p) => p['name'] == _openedPlaylist,
        orElse: () => {'name': '', 'songs': <String>[]},
      );
      List<String> paths = (playlist['songs'] as List<String>);
      baseList = _songs.where((f) => paths.contains(f.path)).toList();
    }

    String query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      baseList = baseList
          .where((f) => getSongName(f.path).toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredSongs = baseList;
    });
  }

  void _deleteSongPermanently(File song) {
    setState(() {
      if (song == _currentSong) {
        _player.stop();
        _currentSong = null;
        _currentIndex = -1;
        isPlaying = false;
        _isPlayingNotifier.value = false;
      }
      _songs.remove(song);
      _recentSongs.remove(song.path);
      _favorites.remove(song.path);
      for (var playlist in _playlists) {
        (playlist['songs'] as List<String>).remove(song.path);
      }
      _applyFilter();
    });
    _saveSongs();
    _saveFavorites();
    _saveRecent();
    _savePlaylists();
    _showSnackBar('🗑️ Song deleted permanently', Colors.red);
  }

  void _removeFromPlaylist(File song) {
    if (_openedPlaylist == null) return;
    setState(() {
      var playlist = _playlists.firstWhere((p) => p['name'] == _openedPlaylist);
      (playlist['songs'] as List<String>).remove(song.path);
      _applyFilter();
    });
    _savePlaylists();
    _showSnackBar('🚫 Removed from $_openedPlaylist', Colors.orange);
  }

  void _toggleFavorite(File song) {
    setState(() {
      if (_favorites.contains(song.path)) {
        _favorites.remove(song.path);
        _showSnackBar('💔 Removed from Favorites', Colors.orange);
      } else {
        _favorites.add(song.path);
        _showSnackBar('❤️ Added to Favorites', Colors.pink);
      }
      _applyFilter();
    });
    _saveFavorites();
  }

  void _showAddToPlaylist(File song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: AppTheme.primaryGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.playlist_add,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        'Add to Playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.shade800, height: 1),
                if (_playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No playlists yet!\nCreate one below 👇',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                  ..._playlists.map((playlist) {
                    bool isIn = (playlist['songs'] as List<String>)
                        .contains(song.path);
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIn ? Icons.check_circle : Icons.playlist_play,
                          color: isIn ? Colors.green : AppTheme.accent,
                        ),
                      ),
                      title: Text(
                        playlist['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: isIn
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
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
                              ? '🚫 Removed from ${playlist['name']}'
                              : '✅ Song added to ${playlist['name']}',
                          isIn ? Colors.orange : Colors.green,
                        );
                      },
                    );
                  }).toList(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _createNewPlaylist(song);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Create New Playlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createNewPlaylist(File song) {
    TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('➕ New Playlist',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter playlist name',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.playlist_play, color: AppTheme.accent),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _playlists.add({
                      'name': nameCtrl.text.trim(),
                      'songs': [song.path],
                    });
                  });
                  _savePlaylists();
                  Navigator.pop(context);
                  _showSnackBar(
                    '✅ Song added to "${nameCtrl.text}"',
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

  void _showMainSongOptions(File song) {
    bool isFav = _favorites.contains(song.path);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildOptionsSheet(
          title: getSongName(song.path),
          songPath: song.path,
          options: [
            _optionItem(
              icon: isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.pinkAccent,
              title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(song);
              },
            ),
            _optionItem(
              icon: Icons.playlist_add,
              color: AppTheme.accent,
              title: 'Add to Playlist',
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylist(song);
              },
            ),
            _optionItem(
              icon: Icons.delete_forever,
              color: Colors.redAccent,
              title: 'Delete Permanently',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(song);
              },
            ),
          ],
        );
      },
    );
  }

  void _showPlaylistSongOptions(File song) {
    bool isFav = _favorites.contains(song.path);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildOptionsSheet(
          title: getSongName(song.path),
          songPath: song.path,
          options: [
            _optionItem(
              icon: Icons.remove_circle_outline,
              color: Colors.orange,
              title: 'Remove from Playlist',
              onTap: () {
                Navigator.pop(context);
                _removeFromPlaylist(song);
              },
            ),
            _optionItem(
              icon: isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.pinkAccent,
              title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(song);
              },
            ),
            _optionItem(
              icon: Icons.delete_forever,
              color: Colors.redAccent,
              title: 'Delete Permanently',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(song);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionsSheet({
    required String title,
    required String songPath,
    required List<Widget> options,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AlbumArtWidget(
                    audioPath: songPath,
                    size: 55,
                    isPlaying: false,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            ...options,
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _optionItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }

  void _confirmDelete(File song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🗑️ Delete Permanently?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Delete "${getSongName(song.path)}" permanently?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteSongPermanently(song);
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

  void _showFullScreenPlayer() {
    if (_currentSong == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.bg, AppTheme.card],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _toggle3D();
                                setModalState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: is3DOn
                                      ? AppTheme.accent.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: is3DOn
                                        ? AppTheme.accent
                                        : Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      is3DOn
                                          ? Icons.surround_sound
                                          : Icons.surround_sound_outlined,
                                      color: is3DOn
                                          ? AppTheme.accent
                                          : Colors.white70,
                                      size: 18,
                                    ),
                                    if (is3DOn) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '3D',
                                        style: TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(
                                _favorites.contains(_currentSong!.path)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _favorites.contains(_currentSong!.path)
                                    ? Colors.pinkAccent
                                    : Colors.white,
                              ),
                              onPressed: () {
                                _toggleFavorite(_currentSong!);
                                setModalState(() {});
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: AlbumArtWidget(
                      audioPath: _currentSong!.path,
                      size: 280,
                      isPlaying: isPlaying,
                      isCircle: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        Text(
                          getSongName(_currentSong!.path),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Local Audio',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                            if (is3DOn) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.accent, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.surround_sound,
                                        color: AppTheme.accent, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      '3D',
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  StreamBuilder<Duration>(
                    stream: _player.onPositionChanged,
                    builder: (context, snapshot) {
                      final currentPosition = snapshot.data ?? Duration.zero;
                      final maxDuration = _duration.inSeconds.toDouble() > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0;
                      final currentValue = currentPosition.inSeconds
                          .toDouble()
                          .clamp(0.0, maxDuration);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor:
                                    AppTheme.primaryGradient[1],
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.2),
                                thumbColor: Colors.white,
                                overlayColor: AppTheme.primaryGradient[1]
                                    .withOpacity(0.3),
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: currentValue,
                                max: maxDuration,
                                onChanged: (value) async {
                                  await _player.seek(
                                      Duration(seconds: value.toInt()));
                                  setModalState(() {});
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatTime(currentPosition),
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12),
                                  ),
                                  Text(
                                    formatTime(_duration),
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            isShuffle
                                ? Icons.shuffle
                                : Icons.shuffle_outlined,
                            color: isShuffle
                                ? AppTheme.primaryGradient[1]
                                : Colors.white54,
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() => isShuffle = !isShuffle);
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous,
                              color: Colors.white, size: 45),
                          onPressed: () {
                            _playPrevious();
                            setModalState(() {});
                          },
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isPlayingNotifier,
                          builder: (context, actuallyPlaying, child) {
                            return Container(
                              height: 75,
                              width: 75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                    colors: AppTheme.primaryGradient),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGradient[0]
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                iconSize: 45,
                                color: Colors.white,
                                icon: Icon(actuallyPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                                onPressed: _togglePlay,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next,
                              color: Colors.white, size: 45),
                          onPressed: () {
                            _playNext();
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isRepeat ? Icons.repeat_one : Icons.repeat,
                            color: isRepeat
                                ? AppTheme.primaryGradient[1]
                                : Colors.white54,
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() => isRepeat = !isRepeat);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(
    int index,
    String name,
    String emoji,
    List<Color> gradient,
  ) {
    bool isActive = _themeIndex == index;
    return GestureDetector(
      onTap: () => _toggleTheme(index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(height: 5),
            Text(
              '$emoji $name',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.bg,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bg, AppTheme.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGradient[0]
                                .withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.headphones,
                          size: 35, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Bhai Bhai Music',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_songs.length} Local Tracks',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade800, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _drawerItem(
                      icon: Icons.library_music,
                      iconColor: Colors.cyan,
                      title: 'Pick Songs',
                      subtitle: 'Select from storage',
                      onTap: () {
                        Navigator.pop(context);
                        _pickSongs();
                      },
                    ),
                    _drawerItem(
                      icon: Icons.folder_open,
                      iconColor: AppTheme.accent,
                      title: 'Scan Music',
                      subtitle: 'Auto scan folders',
                      onTap: () {
                        Navigator.pop(context);
                        _scanDefaultFolder();
                      },
                    ),
                    _drawerItem(
                      icon: Icons.favorite,
                      iconColor: Colors.pinkAccent,
                      title: 'Favorites',
                      subtitle: '${_favorites.length} songs',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedTab = 1;
                          _applyFilter();
                        });
                      },
                    ),
                    _drawerItem(
                      icon: Icons.history,
                      iconColor: Colors.orangeAccent,
                      title: 'Recent',
                      subtitle: '${_recentSongs.length} songs',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedTab = 2;
                          _applyFilter();
                        });
                      },
                    ),
                    _drawerItem(
                      icon: Icons.playlist_play,
                      iconColor: AppTheme.accent,
                      title: 'Playlists',
                      subtitle: '${_playlists.length} playlists',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedTab = 3;
                          _applyFilter();
                        });
                      },
                    ),
                    _drawerItem(
                      icon: Icons.graphic_eq,
                      iconColor: Colors.deepPurpleAccent,
                      title: 'Enhance Sound',
                      subtitle: 'Bass & Immersive audio',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnhanceSoundScreen(
                              player: _player,
                              isDarkTheme: true,
                              onEffectsChanged: (bass, immersive) {
                                setState(() {
                                  _bassLevel = bass;
                                  _immersiveLevel = immersive;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(color: Colors.grey.shade800, height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (is3DOn ? AppTheme.accent : Colors.grey)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          is3DOn
                              ? Icons.surround_sound
                              : Icons.surround_sound_outlined,
                          color: is3DOn ? AppTheme.accent : Colors.grey,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        '3D Audio',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                      ),
                      subtitle: Text(
                        is3DOn ? 'ON - Surround Sound' : 'OFF - Normal Audio',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: is3DOn,
                        onChanged: (value) => _toggle3D(),
                        activeColor: AppTheme.accent,
                      ),
                    ),
                    Divider(color: Colors.grey.shade800, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 10, bottom: 10),
                            child: Text(
                              '🎨 Choose Theme',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildThemeCard(
                                  0,
                                  'Emerald',
                                  '🟢',
                                  AppColors.gradient0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildThemeCard(
                                  1,
                                  'Gold',
                                  '🟡',
                                  AppColors.gradient1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildThemeCard(
                                  2,
                                  'Indigo',
                                  '🔵',
                                  AppColors.gradient2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildThemeCard(
                                  3,
                                  'Purple',
                                  '🟣',
                                  AppColors.gradient3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Version 1.0.0\nMade with ❤️ by Bhai Bhai",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: _buildDrawer(),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bg, AppTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.menu,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: AppTheme.primaryGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGradient[0]
                              .withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bhai Bhai Music',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Feel The Rhythm',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggle3D,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: is3DOn
                            ? AppTheme.accent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: is3DOn
                              ? AppTheme.accent
                              : Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        is3DOn
                            ? Icons.surround_sound
                            : Icons.surround_sound_outlined,
                        color: is3DOn ? AppTheme.accent : Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  onChanged: (_) => _applyFilter(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildTab(0, '🎵 All'),
                    _buildTab(1, '❤️ Favorites'),
                    _buildTab(2, '🕒 Recent'),
                    _buildTab(3, '📁 Playlists'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _selectedTab == 3
                  ? _buildPlaylistsView()
                  : _filteredSongs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            return _buildSongTile(
                                _filteredSongs[index], index);
                          },
                        ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar:
        _currentSong != null ? _buildSlimMiniPlayer() : null,
  );
}
  
  Widget _drawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
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
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSlimMiniPlayer() {
    return GestureDetector(
      onTap: _showFullScreenPlayer,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGradient[0].withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AlbumArtWidget(
                  audioPath: _currentSong!.path,
                  size: 40,
                  isPlaying: isPlaying,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              getSongName(_currentSong!.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (is3DOn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.surround_sound,
                                      color: Colors.white, size: 10),
                                  SizedBox(width: 3),
                                  Text(
                                    '3D',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatTime(_position)} / ${formatTime(_duration)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: Colors.white, size: 24),
                  onPressed: _playPrevious,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlayingNotifier,
                  builder: (context, actuallyPlaying, child) {
                    return IconButton(
                      icon: Icon(
                        actuallyPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 38,
                      ),
                      onPressed: _togglePlay,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white, size: 24),
                  onPressed: _playNext,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _duration.inSeconds > 0
                    ? _position.inSeconds / _duration.inSeconds
                    : 0,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No songs found!';
    String sub = 'Open menu → Pick Songs or Scan';
    IconData icon = Icons.music_off;

    if (_selectedTab == 1) {
      message = 'No favorites yet!';
      sub = 'Long press a song → Add to Favorites';
      icon = Icons.favorite_border;
    } else if (_selectedTab == 2) {
      message = 'No recent songs!';
      sub = 'Play a song to add it here';
      icon = Icons.history;
    } else if (_openedPlaylist != null) {
      message = 'Playlist is empty!';
      sub = 'Add songs via long press';
      icon = Icons.playlist_add;
    }

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
            child: Icon(icon, size: 80, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(File song, int index,
      {bool isFromPlaylist = false}) {
    bool isSelected = _currentSong == song;
    bool isFav = _favorites.contains(song.path);

    return GestureDetector(
      onTap: () => _playSong(song, index),
      onLongPress: () {
        if (isFromPlaylist) {
          _showPlaylistSongOptions(song);
        } else {
          _showMainSongOptions(song);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: AppTheme.primaryGradient)
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
                    color: AppTheme.primaryGradient[0].withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AlbumArtWidget(
              audioPath: song.path,
              size: 45,
              isPlaying: isSelected && isPlaying,
            ),
            const SizedBox(width: 15),
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isFav) ...[
                        const Icon(Icons.favorite,
                            color: Colors.pinkAccent, size: 11),
                        const SizedBox(width: 4),
                      ],
                      if (isSelected && is3DOn) ...[
                        Icon(Icons.surround_sound,
                            color: AppTheme.accent, size: 11),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isSelected && isPlaying
                            ? 'Now Playing'
                            : 'Local Audio',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              ValueListenableBuilder<bool>(
                valueListenable: _isPlayingNotifier,
                builder: (context, actuallyPlaying, child) {
                  return IconButton(
                    icon: Icon(
                      actuallyPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _togglePlay,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
