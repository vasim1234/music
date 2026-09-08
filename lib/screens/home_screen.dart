import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';
import '../services/notification_service.dart';
import 'equalizer_screen.dart';

// ✅ FolderManagerScreen is already in this file at the bottom!

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final bool? isDarkMode;

  const HomeScreen({
    super.key,
    this.onThemeChanged,
    this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ... (rest of your code remains same)

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Player
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _savedFolders = [];
  List<File> _playlist = [];
  List<File> _filteredPlaylist = [];
  List<String> _favorites = [];
  List<String> _recentSongs = [];
  List<Map<String, dynamic>> _customPlaylists = [];
  String _selectedPlaylist = '';

  // State
  int _currentIndex = -1;
  bool isPlaying = false;
  bool _hasPermission = false;
  bool is3DOn = false;
  String _currentView = 'Songs';

  // Duration
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Album art cache
  Map<String, String> _albumArtCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Player Listeners
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      setState(() => isPlaying = state == PlayerState.playing);
      _updateLockScreenControls();
    });
    _player.onPlayerComplete.listen((event) => playNext());

    _loadData();
    _checkPermission();
    _loadAlbumArtCache();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _updateLockScreenControls();
    }
  }

  // UPDATE LOCK SCREEN CONTROLS
  void _updateLockScreenControls() {
    if (_currentIndex >= 0 && _filteredPlaylist.isNotEmpty) {
      String songName = getFileName(_filteredPlaylist[_currentIndex].path);
      NotificationService.showNowPlayingNotification(
        title: songName,
        artist: "Bhai Bhai App",
        isPlaying: isPlaying,
      );
    }
  }

  // ========== ALBUM ART METHODS ==========
  
  // Load album art cache
  Future<void> _loadAlbumArtCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsData = prefs.getString('album_art_cache');
      if (prefsData != null) {
        final Map<String, dynamic> decoded = {};
        final pairs = prefsData.split(',').where((s) => s.isNotEmpty);
        for (var pair in pairs) {
          final parts = pair.split('|||');
          if (parts.length == 2) {
            decoded[parts[0]] = parts[1];
          }
        }
        setState(() {
          _albumArtCache = Map<String, String>.from(decoded.cast<String, String>());
        });
      }
    } catch (e) {
      print('Error loading album art cache: $e');
    }
  }

  // Save album art cache
  Future<void> _saveAlbumArtCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _albumArtCache.entries.map((e) => '${e.key}|||${e.value}').join(',');
      await prefs.setString('album_art_cache', encoded);
    } catch (e) {
      print('Error saving album art cache: $e');
    }
  }

  // Extract album art safely
  Future<String?> _extractAlbumArt(String filePath) async {
    try {
      if (_albumArtCache.containsKey(filePath)) {
        final cachedPath = _albumArtCache[filePath]!;
        if (File(cachedPath).existsSync()) {
          return cachedPath;
        }
      }

      final Tag? tags = await AudioTags.read(filePath);
      if (tags != null && tags.pictures.isNotEmpty) {
        final pictureBytes = tags.pictures.first.bytes;
        final dir = await getApplicationDocumentsDirectory();
        final fileName = '${filePath.hashCode}.jpg';
        final savedImagePath = '${dir.path}/$fileName';
        
        File imageFile = File(savedImagePath);
        await imageFile.writeAsBytes(pictureBytes);

        setState(() {
          _albumArtCache[filePath] = savedImagePath;
        });
        await _saveAlbumArtCache();

        return savedImagePath;
      }
    } catch (e) {
      print('Error extracting album art: $e');
    }
    return null;
  }

  // Get album art with caching
  Future<String?> getAlbumArt(String filePath) async {
    try {
      if (_albumArtCache.containsKey(filePath)) {
        final cachedPath = _albumArtCache[filePath]!;
        if (File(cachedPath).existsSync()) {
          return cachedPath;
        }
      }

      final artPath = await _extractAlbumArt(filePath);
      return artPath;
    } catch (e) {
      print('Error getting album art: $e');
      return null;
    }
  }

  // ========== DATA METHODS ==========
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList('saved_folders');
    List<String>? favs = prefs.getStringList('favorites');
    List<String>? recent = prefs.getStringList('recent_songs');
    List<String>? playlists = prefs.getStringList('custom_playlists');

    if (favs != null) setState(() => _favorites = favs);
    if (recent != null) setState(() => _recentSongs = recent);

    if (playlists != null) {
      setState(() {
        _customPlaylists = playlists.map((p) {
          List<String> parts = p.split('|||');
          return {
            'name': parts[0],
            'songs': parts.length > 1 ? parts[1].split(',').where((s) => s.isNotEmpty).toList() : []
          };
        }).toList();
      });
    }

    if (saved != null) {
      setState(() {
        _savedFolders = saved.map((path) => ({
          'name': path.split('/').last,
          'path': path,
          'isChecked': true
        })).toList();
      });
      await updatePlaylistFromFolders();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> paths = _savedFolders.map((f) => f['path'] as String).toList();
    await prefs.setStringList('saved_folders', paths);
    await prefs.setStringList('favorites', _favorites);
    await prefs.setStringList('recent_songs', _recentSongs);

    List<String> playlistData = _customPlaylists.map<String>((p) =>
        p['name'].toString() + '|||' + (p['songs'] as List<String>).join(',')).toList();
    await prefs.setStringList('custom_playlists', playlistData);
  }

  // ========== PERMISSION ==========
  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      var storageStatus = await Permission.storage.status;
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted && !manageStatus.isGranted) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
        await Permission.audio.request();
      }
      storageStatus = await Permission.storage.status;
      manageStatus = await Permission.manageExternalStorage.status;
      setState(() {
        _hasPermission = storageStatus.isGranted || manageStatus.isGranted;
      });
      _loadData();
    }
  }

  // ========== AUDIO SCANNING ==========

Future<List<File>> _getAudioFilesSafely(Directory dir) async {
  List<File> audioFiles = [];
  try {
    print('🔍 Scanning directory: ${dir.path}');
    List<FileSystemEntity> entities = dir.listSync(recursive: false);
    for (FileSystemEntity entity in entities) {
      try {
        if (entity is File) {
          String path = entity.path.toLowerCase();
          if (path.endsWith('.mp3') || path.endsWith('.m4a') || path.endsWith('.wav') ||
              path.endsWith('.aac') || path.endsWith('.ogg') || path.endsWith('.flac') ||
              path.endsWith('.wma')) {
            audioFiles.add(entity);
            print('🎵 Found audio file: ${entity.path.split('/').last}');
          }
        } else if (entity is Directory) {
          if (!entity.path.split('/').last.startsWith('.')) {
            audioFiles.addAll(await _getAudioFilesSafely(entity));
          }
        }
      } catch (e) {
        print('⚠️ Error accessing: $e');
      }
    }
  } catch (e) {
    print('⚠️ Error scanning directory: $e');
  }
  print('📊 Total audio files in ${dir.path}: ${audioFiles.length}');
  return audioFiles;
}

Future<void> updatePlaylistFromFolders() async {
  print('🔄 Updating playlist from folders...');
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('🔄 Scanning folders...')),
  );
  
  setState(() {
    _playlist = [];
    _filteredPlaylist = [];
  });
  
  List<File> newSongs = [];
  for (var folder in _savedFolders) {
    if (folder['isChecked'] == true) {
      Directory dir = Directory(folder['path']);
      if (dir.existsSync()) {
        print('📁 Scanning: ${folder['path']}');
        List<File> foundSongs = await _getAudioFilesSafely(dir);
        print('🎵 Found: ${foundSongs.length} songs in this folder');
        newSongs.addAll(foundSongs);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📁 ${folder['name']}: ${foundSongs.length} songs'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('⚠️ Folder not found: ${folder['path']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Folder not found: ${folder['name']}')),
        );
      }
    }
  }
  
  print('🎵 Total songs found: ${newSongs.length}');
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ ${newSongs.length} songs found!'),
      backgroundColor: newSongs.length > 0 ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
  
  setState(() {
    _playlist = newSongs;
    filterSearchResults(_searchController.text);
  });
}

  // ========== PLAYLIST METHODS ==========
  void createNewPlaylist() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.playlist_add, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text('Create Playlist')
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter playlist name',
                prefixIcon: const Icon(Icons.music_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Example: Gym, Safar, Romantic',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _customPlaylists.add({
                    'name': nameController.text.trim(),
                    'songs': <String>[]
                  });
                });
                _saveData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Playlist "${nameController.text}" created!'),
                    backgroundColor: Colors.green,
                  ),
                );
                setView('Playlists');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void addToPlaylist(String songPath) {
    if (_customPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No playlists! Create one first.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Create',
            textColor: Colors.white,
            onPressed: createNewPlaylist,
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add to Playlist'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: _customPlaylists.map((playlist) {
                  bool isInPlaylist = (playlist['songs'] as List<String>).contains(songPath);
                  return ListTile(
                    leading: Icon(
                      isInPlaylist ? Icons.check_circle : Icons.add_circle_outline,
                      color: isInPlaylist ? Colors.green : Colors.grey,
                    ),
                    title: Text(playlist['name']),
                    subtitle: Text('${(playlist['songs'] as List<String>).length} songs'),
                    onTap: () {
                      setStateDialog(() {
                        if (isInPlaylist) {
                          (playlist['songs'] as List<String>).remove(songPath);
                        } else {
                          (playlist['songs'] as List<String>).add(songPath);
                        }
                      });
                      setState(() {});
                      _saveData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isInPlaylist
                              ? 'Removed from ${playlist['name']}'
                              : 'Added to ${playlist['name']}'),
                          backgroundColor: isInPlaylist ? Colors.red : Colors.green,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========== PLAYER METHODS ==========
  void openFolderManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderManagerScreen(
          folders: _savedFolders,
          onFoldersUpdated: () async {
            await _saveData();
            await updatePlaylistFromFolders();
            setState(() {});
          },
        ),
      ),
    );
  }

  void toggle3D() {
    setState(() {
      is3DOn = !is3DOn;
      if (is3DOn) {
        _player.setVolume(0.8);
        _player.setBalance(0.5);
      } else {
        _player.setVolume(1.0);
        _player.setBalance(0.0);
      }
    });
  }

  Future<void> playSong(String path) async {
    await _player.play(DeviceFileSource(path));
    addToRecent(path);
    _updateLockScreenControls();
  }

  void playNext() {
    if (_filteredPlaylist.isNotEmpty && _currentIndex < _filteredPlaylist.length - 1) {
      setState(() => _currentIndex++);
      playSong(_filteredPlaylist[_currentIndex].path);
    }
  }

  void playPrevious() {
    if (_filteredPlaylist.isNotEmpty && _currentIndex > 0) {
      setState(() => _currentIndex--);
      playSong(_filteredPlaylist[_currentIndex].path);
    }
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return twoDigits(d.inMinutes.remainder(60)) + ":" + twoDigits(d.inSeconds.remainder(60));
  }

  String getFileName(String path) {
    String name = path.split('/').last;
    name = name.replaceAll(RegExp(r'\.(mp3|m4a|wav|aac|ogg|flac|wma)$', caseSensitive: false), '');
    return name
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }

  void setView(String viewName) {
    setState(() {
      _currentView = viewName;
      _searchController.clear();
      filterSearchResults('');
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      List<File> baseList = [];
      if (_currentView == 'Favorites') {
        baseList = _playlist.where((f) => _favorites.contains(f.path)).toList();
      } else if (_currentView == 'Recent') {
        baseList = _recentSongs.map((p) => File(p)).where((f) => f.existsSync()).toList();
      } else if (_currentView == 'PlaylistDetail') {
        var playlist = _customPlaylists.firstWhere(
          (p) => p['name'] == _selectedPlaylist,
          orElse: () => {'name': '', 'songs': <String>[]},
        );
        List<String> songPaths = (playlist['songs'] as List<String>);
        baseList = _playlist.where((f) => songPaths.contains(f.path)).toList();
      } else {
        baseList = _playlist;
      }
      if (query.isEmpty) {
        _filteredPlaylist = baseList;
      } else {
        _filteredPlaylist = baseList
            .where((f) => getFileName(f.path).toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void toggleFavorite(String path) async {
    setState(() {
      if (_favorites.contains(path)) {
        _favorites.remove(path);
      } else {
        _favorites.add(path);
      }
      if (_currentView == 'Favorites') filterSearchResults(_searchController.text);
    });
    await _saveData();
  }

  Future<void> addToRecent(String path) async {
    setState(() {
      _recentSongs.remove(path);
      _recentSongs.insert(0, path);
      if (_recentSongs.length > 50) _recentSongs.removeLast();
    });
    await _saveData();
  }

  // ========== DEFAULT ART WIDGETS ==========
  
  Widget _defaultAlbumArt({double size = 44}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(Icons.music_note, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _defaultLargeAlbumArt() {
    return Container(
      height: 280,
      width: 280,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4C83FF), Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.music_note, size: 100, color: Colors.white),
    );
  }

  Widget _buildAlbumArt(String path, {double size = 44}) {
    return FutureBuilder<String?>(
      future: getAlbumArt(path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.file(
              File(snapshot.data!),
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _defaultAlbumArt(size: size),
            ),
          );
        }
        return _defaultAlbumArt(size: size);
      },
    );
  }

  // ========== FULL SCREEN PLAYER ==========
  void openFullScreenPlayer() {
    if (_currentIndex == -1 || _filteredPlaylist.isEmpty) return;
    String currentPath = _filteredPlaylist[_currentIndex].path;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Now Playing",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(
                            is3DOn ? Icons.surround_sound : Icons.surround_sound_outlined,
                            color: is3DOn ? Colors.purpleAccent : Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            toggle3D();
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  // Album Art - Large
                  FutureBuilder<String?>(
                    future: getAlbumArt(currentPath),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Container(
                          height: 280,
                          width: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _defaultLargeAlbumArt(),
                            ),
                          ),
                        );
                      }
                      return _defaultLargeAlbumArt();
                    },
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        Text(
                          getFileName(currentPath),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Local Audio",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<Duration>(
                    stream: _player.onPositionChanged,
                    builder: (context, snapshot) {
                      Duration pos = snapshot.data ?? _position;
                      double maxSec = _duration.inSeconds.toDouble();
                      double currentSec = pos.inSeconds.toDouble();
                      if (maxSec <= 0) maxSec = 1.0;
                      currentSec = currentSec.clamp(0.0, maxSec);

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              activeTrackColor: Colors.purpleAccent,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayColor: Colors.purpleAccent.withOpacity(0.2),
                            ),
                            child: Slider(
                              min: 0,
                              max: maxSec,
                              value: currentSec,
                              onChanged: (value) async {
                                await _player.seek(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatTime(pos), style: const TextStyle(color: Colors.white54)),
                                Text(formatTime(_duration), style: const TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _favorites.contains(currentPath)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _favorites.contains(currentPath)
                                ? Colors.deepPurpleAccent
                                : Colors.white54,
                            size: 28,
                          ),
                          onPressed: () {
                            toggleFavorite(currentPath);
                            setModalState(() {});
                            setState(() {});
                          },
                        ),
                        IconButton(
                          iconSize: 45,
                          color: Colors.white,
                          icon: const Icon(Icons.skip_previous),
                          onPressed: () {
                            playPrevious();
                            setModalState(() {});
                          },
                        ),
                        StreamBuilder<PlayerState>(
                          stream: _player.onPlayerStateChanged,
                          builder: (context, snapshot) {
                            bool playing = snapshot.data == PlayerState.playing || isPlaying;
                            return Container(
                              height: 65,
                              width: 65,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.purpleAccent,
                              ),
                              child: IconButton(
                                iconSize: 40,
                                color: Colors.white,
                                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                                onPressed: () async {
                                  playing ? await _player.pause() : await _player.resume();
                                },
                              ),
                            );
                          },
                        ),
                        IconButton(
                          iconSize: 45,
                          color: Colors.white,
                          icon: const Icon(Icons.skip_next),
                          onPressed: () {
                            playNext();
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.playlist_add, color: Colors.white54, size: 28),
                          onPressed: () => addToPlaylist(currentPath),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ========== MINI PLAYER ==========
  Widget buildMiniPlayer() {
    if (_currentIndex < 0 || _filteredPlaylist.isEmpty) return const SizedBox.shrink();
    String currentPath = _filteredPlaylist[_currentIndex].path;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink.shade100, Colors.purple.shade100]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: _buildAlbumArt(currentPath, size: 44),
        title: Text(
          getFileName(currentPath),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: const Text(
          "Local Audio",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.black54,
                size: 35,
              ),
              onPressed: () {
                isPlaying ? _player.pause() : _player.resume();
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.black54, size: 30),
              onPressed: playNext,
            ),
          ],
        ),
        onTap: openFullScreenPlayer,
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.cancelNotification();
    super.dispose();
  }

  // ========== BUILD METHOD ==========
  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('BHAI BHAI APP'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 100, color: Colors.deepPurple),
                const SizedBox(height: 30),
                const Text(
                  'Storage Permission Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please grant storage permission to access your music files.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _checkPermission,
                  icon: const Icon(Icons.folder_open),
                  label: const Text(
                    'Grant Permission',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: filterSearchResults,
            decoration: const InputDecoration(
              hintText: "Search songs, playlists...",
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          if (widget.isDarkMode != null)
            IconButton(
              icon: Icon(widget.isDarkMode! ? Icons.dark_mode : Icons.light_mode),
              onPressed: () {
                if (widget.onThemeChanged != null) {
                  widget.onThemeChanged!(!widget.isDarkMode!);
                }
              },
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFFD946EF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headphones, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Bhai Bhai App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_playlist.length} Local Tracks',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder, color: Colors.deepPurple),
                    title: const Text('Choose Folders', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      openFolderManager();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blueAccent),
                    title: const Text('Scan Music', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      updatePlaylistFromFolders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scanning...')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lyrics, color: Colors.teal),
                    title: const Text('Lyrics', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lyrics feature coming soon! 🎵')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.indigo),
                    title: const Text('Visualizer', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Visualizer feature coming soon! 📊')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.equalizer, color: Colors.orange),
                    title: const Text('Equalizer & Effects', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EqualizerScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette, color: Colors.pink),
                    title: const Text('Themes', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Themes Coming Soon! 🎨')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.grey.shade700),
                    title: const Text('Settings'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.green),
                    title: const Text('Share App'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Version 1.0.0\nMade with ❤️ by Bhai Bhai",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Access Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setView('Favorites'),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF982B4D), Color(0xFFC7436B)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: _currentView == 'Favorites'
                            ? Border.all(color: Colors.black87, width: 3)
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              _currentView == 'Favorites' ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Favourites",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setView('Playlists'),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E5F74), Color(0xFF2C7D99)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: _currentView == 'Playlists'
                            ? Border.all(color: Colors.black87, width: 3)
                            : null,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.queue_music, color: Colors.white, size: 20),
                            SizedBox(height: 5),
                            Text(
                              "Playlists",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setView('Recent'),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(15),
                        border: _currentView == 'Recent'
                            ? Border.all(color: Colors.purpleAccent, width: 3)
                            : null,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.history, color: Colors.white, size: 20),
                            SizedBox(height: 5),
                            Text(
                              "Recent",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setView('Songs'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: _currentView == 'Songs' ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Songs",
                      style: TextStyle(
                        color: _currentView == 'Songs' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setView('Favorites'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: _currentView == 'Favorites' ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Favorites",
                      style: TextStyle(
                        color: _currentView == 'Favorites' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setView('Recent'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: _currentView == 'Recent' ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Recent",
                      style: TextStyle(
                        color: _currentView == 'Recent' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setView('Playlists'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: _currentView == 'Playlists' ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Playlists",
                      style: TextStyle(
                        color: _currentView == 'Playlists' ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          if (_currentView == 'Playlists')
            Expanded(
              child: _customPlaylists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music, size: 80, color: Colors.deepPurple.shade100),
                          const SizedBox(height: 20),
                          const Text(
                            "No Playlists Yet",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Create your first playlist!",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text("Create Playlist", style: TextStyle(fontSize: 16)),
                            onPressed: createNewPlaylist,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _customPlaylists.length,
                      itemBuilder: (context, index) {
                        var playlist = _customPlaylists[index];
                        int songCount = (playlist['songs'] as List<String>).length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.purple.shade300, Colors.deepPurple],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.playlist_play, color: Colors.white),
                            ),
                            title: Text(
                              playlist['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              '$songCount songs • ${songCount > 0 ? "Tap to play" : "Add songs"}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (songCount > 0)
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, color: Colors.deepPurple, size: 28),
                                    onPressed: () {
                                      _selectedPlaylist = playlist['name'];
                                      setView('PlaylistDetail');
                                      filterSearchResults('');
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text('Delete Playlist?'),
                                        content: Text(
                                          'Are you sure you want to delete "${playlist['name']}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _customPlaylists.removeAt(index);
                                              });
                                              _saveData();
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Playlist deleted!'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              _selectedPlaylist = playlist['name'];
                              setView('PlaylistDetail');
                              filterSearchResults('');
                            },
                          ),
                        );
                      },
                    ),
            )
          else if (_currentView == 'PlaylistDetail')
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => setView('Playlists'),
                        ),
                        Expanded(
                          child: Text(
                            _selectedPlaylist,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredPlaylist.length} songs',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredPlaylist.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_off, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                const Text(
                                  'No songs in this playlist',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Songs'),
                                  onPressed: () => setView('Songs'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredPlaylist.length,
                            itemBuilder: (context, index) {
                              String path = _filteredPlaylist[index].path;
                              bool isCurrent = _currentIndex == index && isPlaying;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCurrent ? Colors.deepPurple.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: _buildAlbumArt(path, size: 40),
                                  title: Text(
                                    getFileName(path),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrent ? Colors.deepPurple : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Local Audio",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        var playlist = _customPlaylists.firstWhere(
                                          (p) => p['name'] == _selectedPlaylist,
                                        );
                                        (playlist['songs'] as List<String>).remove(path);
                                      });
                                      _saveData();
                                      filterSearchResults('');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed from playlist'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    setState(() => _currentIndex = index);
                                    playSong(path);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: _filteredPlaylist.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentView == 'Recent'
                                ? Icons.history_toggle_off
                                : Icons.library_music,
                            size: 60,
                            color: Colors.black12,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currentView == 'Favorites'
                                ? "No favorites yet"
                                : _currentView == 'Recent'
                                    ? "No listening history yet"
                                    : "No songs found",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentView == 'Songs')
                            Column(
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                  "Open side menu (☰) to choose folders",
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: openFolderManager,
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text("Open Folder Manager"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPlaylist.length,
                      itemBuilder: (context, index) {
                        bool isCurrent = _currentIndex == index && isPlaying;
                        String path = _filteredPlaylist[index].path;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.deepPurple.shade50 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: _buildAlbumArt(path, size: 50),
                            title: Text(
                              getFileName(path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent ? Colors.deepPurple : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              "Local Audio",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _favorites.contains(path) ? Icons.favorite : Icons.favorite_border,
                                    color: _favorites.contains(path)
                                        ? Colors.deepPurpleAccent
                                        : Colors.grey,
                                    size: 22,
                                  ),
                                  onPressed: () => toggleFavorite(path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.playlist_add, color: Colors.grey, size: 22),
                                  onPressed: () => addToPlaylist(path),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() => _currentIndex = index);
                              playSong(path);
                            },
                          ),
                        );
                      },
                    ),
            ),
          buildMiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones),
            label: "My music",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: "Watch",
          ),
        ],
      ),
    );
  }
}

// ========== FOLDER MANAGER SCREEN ==========
class FolderManagerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> folders;
  final VoidCallback onFoldersUpdated;

  const FolderManagerScreen({
    Key? key,
    required this.folders,
    required this.onFoldersUpdated,
  }) : super(key: key);

  @override
  State<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      var manageStatus = await Permission.manageExternalStorage.status;
      setState(() {
        _hasPermission = storageStatus.isGranted || manageStatus.isGranted;
      });
    }
  }

  Future<void> _requestPermission() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    await Permission.audio.request();
    await _checkPermission();
    widget.onFoldersUpdated();
  }

  Future<void> addNewFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        bool exists = widget.folders.any((f) => f['path'] == selectedDirectory);
        if (!exists) {
          setState(() {
            widget.folders.add({
              'name': selectedDirectory.split('/').last,
              'path': selectedDirectory,
              'isChecked': true,
            });
          });
          widget.onFoldersUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added: ' + selectedDirectory.split('/').last)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder already added!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: " + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose folders to display',
          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
            onPressed: () {
              _checkPermission();
              widget.onFoldersUpdated();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasPermission)
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    "⚠️ Storage Permission Required!",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Please allow Storage Access to scan your songs.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: _requestPermission,
                    child: const Text("Grant Permission", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.folders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No folders added yet", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 5),
                        Text(
                          "Tap + below to add a folder",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.folders.length,
                    itemBuilder: (context, index) {
                      var folder = widget.folders[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.folder, color: Colors.deepPurpleAccent, size: 30),
                          ),
                          title: Text(
                            folder['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            folder['path'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              setState(() {
                                folder['isChecked'] = !folder['isChecked'];
                              });
                              widget.onFoldersUpdated();
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: folder['isChecked'] ? Colors.black87 : Colors.transparent,
                                border: Border.all(color: Colors.black87, width: 2),
                              ),
                              child: folder['isChecked']
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Folder",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: addNewFolder,
      ),
    );
  }
}

