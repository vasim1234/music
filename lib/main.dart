import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'theme/app_colors.dart';

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

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
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
  bool _isLuxeTheme = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = -1;
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _openedPlaylist = null;
          _applyFilter();
        });
      }
    });

    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      setState(() => isPlaying = state == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) => _playNext());
    _checkPermission();
    _loadSavedData();
    _loadTheme();
  }

  // ✅ LOAD THEME
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLuxe = prefs.getBool('isLuxeTheme') ?? true;
    setState(() {
      _isLuxeTheme = isLuxe;
      AppTheme.isLuxeTheme = isLuxe;
    });
  }

  // ✅ TOGGLE THEME
  Future<void> _toggleTheme(bool isLuxe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLuxeTheme', isLuxe);
    setState(() {
      _isLuxeTheme = isLuxe;
      AppTheme.isLuxeTheme = isLuxe;
    });
    _showSnackBar(
      isLuxe ? '🎨 Luxe Purple theme applied' : '🎨 Cyber Neon theme applied',
      AppTheme.accent,
    );
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
        dialogTitle: 'Select Songs',
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
    setState(() {
      _currentSong = song;
      _currentIndex = index;
    });

    if (!_recentSongs.contains(song.path)) {
      _recentSongs.insert(0, song.path);
      if (_recentSongs.length > 20) _recentSongs.removeLast();
      await _saveRecent();
    }

    await _player.play(DeviceFileSource(song.path));
  }

  void _togglePlay() {
    isPlaying ? _player.pause() : _player.resume();
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
                          gradient: LinearGradient(colors: AppTheme.primaryGradient),
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
                      'No playlists yet!\nCreate your first playlist below 👇',
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
                      subtitle: Text(
                        '${(playlist['songs'] as List<String>).length} songs',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('➕ New Playlist',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter playlist name',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon:
                  Icon(Icons.playlist_play, color: AppTheme.accent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppTheme.accent, width: 2),
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
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppTheme.primaryGradient),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 28),
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }

  void _confirmDelete(File song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '🗑️ Delete Permanently?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Delete "${getSongName(song.path)}" permanently?\n\nThis will remove it from your device and all playlists.',
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

  @override
  void dispose() {
    _tabController.dispose();
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.bg,
              AppTheme.bg.withOpacity(0.95),
              AppTheme.card,
            ],
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
                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGradient[0].withOpacity(0.5),
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

              // TABS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(colors: AppTheme.primaryGradient),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGradient[0].withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '🎵 All'),
                      Tab(text: '❤️ Favorites'),
                      Tab(text: '🕒 Recent'),
                      Tab(text: '📁 Playlists'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // CONTENT
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

  Widget _buildPlaylistsView() {
    if (_openedPlaylist != null) {
      var playlist = _playlists.firstWhere(
        (p) => p['name'] == _openedPlaylist,
        orElse: () => {'name': '', 'songs': <String>[]},
      );
      int count = (playlist['songs'] as List<String>).length;

      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.primaryGradient),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGradient[0].withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _openedPlaylist = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _openedPlaylist!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$count songs',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  GestureDetector(
                    onTap: () {
                      if (_filteredSongs.isNotEmpty) {
                        _playSong(_filteredSongs[0], 0);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_arrow,
                              color: Colors.white, size: 20),
                          SizedBox(width: 5),
                          Text(
                            'Play All',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredSongs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      return _buildSongTile(
                        _filteredSongs[index],
                        index,
                        isFromPlaylist: true,
                      );
                    },
                  ),
          ),
        ],
      );
    }

    if (_playlists.isEmpty) {
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
              child: Icon(Icons.playlist_add,
                  size: 80, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            const Text(
              'No playlists yet!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press any song → Add to Playlist',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        var playlist = _playlists[index];
        int count = (playlist['songs'] as List<String>).length;

        return GestureDetector(
          onTap: () {
            setState(() {
              _openedPlaylist = playlist['name'];
              _applyFilter();
            });
          },
          onLongPress: () => _confirmDeletePlaylist(index),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient
                    .map((c) => c.withOpacity(0.3))
                    .toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGradient[0].withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count songs',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletePlaylist(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🗑️ Delete Playlist?',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "${_playlists[index]['name']}"?',
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
            ),
            onPressed: () {
              setState(() {
                _playlists.removeAt(index);
              });
              _savePlaylists();
              Navigator.pop(context);
              _showSnackBar('🗑️ Playlist deleted', Colors.red);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
                colors: [
                  AppTheme.bg,
                  AppTheme.bg.withOpacity(0.95),
                  AppTheme.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                  ),
                  Container(
                    margin: const EdgeInsets.all(30),
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGradient[0].withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note,
                        size: 130, color: Colors.white),
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
                        const Text(
                          'Local Audio',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            activeTrackColor: AppTheme.primaryGradient[1],
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: Colors.white,
                            overlayColor:
                                AppTheme.primaryGradient[1].withOpacity(0.3),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
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
                              await _player
                                  .seek(Duration(seconds: value.toInt()));
                              setModalState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatTime(_position),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              Text(formatTime(_duration),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            isShuffle ? Icons.shuffle : Icons.shuffle_outlined,
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
                        Container(
                          height: 75,
                          width: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                LinearGradient(colors: AppTheme.primaryGradient),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.primaryGradient[0].withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 45,
                            color: Colors.white,
                            icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              _togglePlay();
                              setModalState(() {});
                            },
                          ),
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.bg,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.bg,
              AppTheme.card,
            ],
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
                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGradient[0].withOpacity(0.5),
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
                      iconColor: AppTheme.secondaryGradient[0],
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
                        _tabController.animateTo(1);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.history,
                      iconColor: Colors.orangeAccent,
                      title: 'Recent',
                      subtitle: '${_recentSongs.length} songs',
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(2);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.playlist_play,
                      iconColor: AppTheme.accent,
                      title: 'Playlists',
                      subtitle: '${_playlists.length} playlists',
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(3);
                      },
                    ),
                    Divider(color: Colors.grey.shade800, height: 1),
                    // ✅ THEME SELECTOR
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
                                child: GestureDetector(
                                  onTap: () => _toggleTheme(true),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppColors.primaryGradientA,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isLuxeTheme
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          _isLuxeTheme
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          'Luxe\nPurple',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _toggleTheme(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppColors.primaryGradientB,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !_isLuxeTheme
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          !_isLuxeTheme
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          'Cyber\nNeon',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
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
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note,
                      color: Colors.white, size: 20),
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
                          fontSize: 13,
                        ),
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
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 38,
                  ),
                  onPressed: _togglePlay,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Colors.white24, Colors.white10])
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade700,
                          Colors.grey.shade800
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected && isPlaying
                    ? Icons.graphic_eq
                    : Icons.music_note,
                color: Colors.white,
                size: 22,
              ),
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
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _togglePlay,
              ),
          ],
        ),
      ),
    );
  }
}
