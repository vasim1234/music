import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'album_art_service.dart';
import 'enhance_sound_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'video_player_screen.dart';

// ✅ 4 PREMIUM THEMES (Dark + Light)
class AppColors {
  static const Color bg0 = Color(0xFF0B1310);
  static const Color card0 = Color(0xFF13221C);
  static const Color accent0 = Color(0xFF34D399);
  static const List<Color> gradient0 = [Color(0xFF059669), Color(0xFF34D399)];

  static const Color bg1 = Color(0xFF121212);
  static const Color card1 = Color(0xFF1E1E1E);
  static const Color accent1 = Color(0xFFD4AF37);
  static const List<Color> gradient1 = [Color(0xFFD4AF37), Color(0xFFC5A059)];

  static const Color bg2 = Color(0xFF0A0E1A);
  static const Color card2 = Color(0xFF141B2D);
  static const Color accent2 = Color(0xFF06B6D4);
  static const List<Color> gradient2 = [Color(0xFF4F46E5), Color(0xFF06B6D4)];

  static const Color bg3 = Color(0xFF0F0F14);
  static const Color card3 = Color(0xFF181820);
  static const Color accent3 = Color(0xFF8B5CF6);
  static const List<Color> gradient3 = [Color(0xFF8B5CF6), Color(0xFFD946EF)];

  static const Color lbg0 = Color(0xFFF5F9F7);
  static const Color lcard0 = Color(0xFFFFFFFF);
  static const Color laccent0 = Color(0xFF059669);
  static const List<Color> lgradient0 = [Color(0xFF059669), Color(0xFF34D399)];

  static const Color lbg1 = Color(0xFFFAF7F0);
  static const Color lcard1 = Color(0xFFFFFFFF);
  static const Color laccent1 = Color(0xFFB8860B);
  static const List<Color> lgradient1 = [Color(0xFFD4AF37), Color(0xFFB8860B)];

  static const Color lbg2 = Color(0xFFF0F4FA);
  static const Color lcard2 = Color(0xFFFFFFFF);
  static const Color laccent2 = Color(0xFF0284C7);
  static const List<Color> lgradient2 = [Color(0xFF4F46E5), Color(0xFF06B6D4)];

  static const Color lbg3 = Color(0xFFF7F5FB);
  static const Color lcard3 = Color(0xFFFFFFFF);
  static const Color laccent3 = Color(0xFF7C3AED);
  static const List<Color> lgradient3 = [Color(0xFF8B5CF6), Color(0xFFD946EF)];
}

class AppTheme {
  static int themeIndex = 0;
  static bool isLightMode = false;

  static Color get bg {
    if (isLightMode) {
      switch (themeIndex) {
        case 0: return AppColors.lbg0;
        case 1: return AppColors.lbg1;
        case 2: return AppColors.lbg2;
        case 3: return AppColors.lbg3;
        default: return AppColors.lbg0;
      }
    }
    switch (themeIndex) {
      case 0: return AppColors.bg0;
      case 1: return AppColors.bg1;
      case 2: return AppColors.bg2;
      case 3: return AppColors.bg3;
      default: return AppColors.bg0;
    }
  }

  static Color get card {
    if (isLightMode) {
      switch (themeIndex) {
        case 0: return AppColors.lcard0;
        case 1: return AppColors.lcard1;
        case 2: return AppColors.lcard2;
        case 3: return AppColors.lcard3;
        default: return AppColors.lcard0;
      }
    }
    switch (themeIndex) {
      case 0: return AppColors.card0;
      case 1: return AppColors.card1;
      case 2: return AppColors.card2;
      case 3: return AppColors.card3;
      default: return AppColors.card0;
    }
  }

  static Color get accent {
    if (isLightMode) {
      switch (themeIndex) {
        case 0: return AppColors.laccent0;
        case 1: return AppColors.laccent1;
        case 2: return AppColors.laccent2;
        case 3: return AppColors.laccent3;
        default: return AppColors.laccent0;
      }
    }
    switch (themeIndex) {
      case 0: return AppColors.accent0;
      case 1: return AppColors.accent1;
      case 2: return AppColors.accent2;
      case 3: return AppColors.accent3;
      default: return AppColors.accent0;
    }
  }

  static List<Color> get primaryGradient {
    if (isLightMode) {
      switch (themeIndex) {
        case 0: return AppColors.lgradient0;
        case 1: return AppColors.lgradient1;
        case 2: return AppColors.lgradient2;
        case 3: return AppColors.lgradient3;
        default: return AppColors.lgradient0;
      }
    }
    switch (themeIndex) {
      case 0: return AppColors.gradient0;
      case 1: return AppColors.gradient1;
      case 2: return AppColors.gradient2;
      case 3: return AppColors.gradient3;
      default: return AppColors.gradient0;
    }
  }

  static Color get text => isLightMode ? const Color(0xFF1A1A1A) : Colors.white;
  static Color get subText => isLightMode ? const Color(0xFF6B6B6B) : Colors.grey.shade500;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 APP STARTING');
  try {
    await initAudioService();
    debugPrint('✅ AUDIO SERVICE INITIALIZED');
  } catch (e) {
    debugPrint('❌ AUDIO SERVICE ERROR: $e');
  }
  debugPrint('🎵 RUNNING APP');
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
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);
  List<File> _songs = [];
  List<File> _filteredSongs = [];
  List<String> _favorites = [];
  List<String> _recentSongs = [];
  List<Map<String, dynamic>> _playlists = [];
  String? _openedPlaylist;
  File? _currentSong;
  bool isPlaying = false;
  bool is3DOn = false;
  bool isShuffle = false;
  bool isRepeat = false;
  bool isRepeatOne = false;

  Map<String, List<File>> _songsByFolder = {};
  String? _selectedFolder;

  List<File> _videos = [];
  Map<String, List<File>> _videosByFolder = {};
  String? _selectedVideoFolder;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = -1;
  int _selectedTab = 0;
  int _themeIndex = 0;

  List<String> _hiddenFolders = [];
  bool _hideBanner = false;
  int _sortMode = 0;

  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _fallbackPlayer = AudioPlayer();

  bool _isSongInHiddenFolder(File song) {
    String folderName = song.parent.path.split('/').last;
    if (folderName.isEmpty) folderName = 'Root';
    return _hiddenFolders.contains(folderName);
  }

  List<File> get _visibleSongs =>
      _songs.where((f) => !_isSongInHiddenFolder(f)).toList();

  bool _isRecordingName(String name) {
    String n = name.trim().toLowerCase();
    if (RegExp(r'^\d{7,}').hasMatch(n)) return true;
    if (RegExp(r'^\d{1,2}\s+\w{3},?\s+\d{1,2}\.\d{2}').hasMatch(n)) return true;
    const recKeywords = [
      'call_rec', 'callrec', 'call record', 'record_', 'recording',
      'audio_20', 'voice_', 'voice rec', 'sound_rec',
    ];
    for (String kw in recKeywords) {
      if (n.contains(kw)) return true;
    }
    if (RegExp(r'^[\d\s\-_().]+$').hasMatch(n)) return true;
    return false;
  }

  bool _isVoiceNoteFile(File f) {
    String p = f.path.toLowerCase();
    if (p.endsWith('.opus') ||
        p.endsWith('.ogg') ||
        p.endsWith('.amr') ||
        p.endsWith('.3gp')) return true;
    if (p.contains('aud-20') ||
        p.contains('ptt-20') ||
        p.contains('broadcast') ||
        p.contains('voice note') ||
        p.contains('vn_') ||
        p.contains('_vn')) return true;
    if (p.contains('/whatsapp audio/') ||
        p.contains('/voice notes/') ||
        p.contains('/voicerecorder/') ||
        p.contains('/voice recorder/') ||
        p.contains('/call_rec/') ||
        p.contains('/callrec/') ||
        p.contains('/call recording/') ||
        p.contains('/callrecordings/') ||
        p.contains('/sound_recorder/') ||
        p.contains('/recordings/')) return true;
    try {
      int sizeKB = (f.lengthSync() / 1024).round();
      if (sizeKB < 300) return true;
    } catch (e) {}
    return false;
  }

  @override
  void initState() {
    super.initState();
    AlbumArtService.init();
    _requestNotificationPermission();

    if (audioHandler == null) {
      _setupFallbackPlayer();
    } else {
      audioHandler!.playingStream.listen((playing) {
        if (mounted) {
          setState(() => isPlaying = playing);
          _isPlayingNotifier.value = playing;
        }
      });
      audioHandler!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      audioHandler!.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      });
      audioHandler!.mediaItem.listen((item) {
        if (item != null && mounted) {
          setState(() {
            _currentSong = File(item.id);
            _currentIndex = _filteredSongs.indexWhere((f) => f.path == item.id);
            if (_currentIndex == -1) _currentIndex = 0;
          });
        }
      });
    }

    _checkPermission();
    _loadSavedData();
    _loadVideos();
    _loadTheme();
    _loadHiddenFolders();
    _loadSortMode();
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  void _setupFallbackPlayer() {
    _fallbackPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      if (mounted) {
        setState(() => isPlaying = playing);
        _isPlayingNotifier.value = playing;
      }
      if (state.processingState == ProcessingState.completed) {
        _playNextFallback();
      }
    });
    _fallbackPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
    _fallbackPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  void _playNextFallback() {
    if (_filteredSongs.isEmpty) return;
    int next;
    if (isShuffle) {
      next = DateTime.now().millisecondsSinceEpoch % _filteredSongs.length;
    } else if (isRepeatOne) {
      next = _currentIndex;
    } else {
      next = (_currentIndex + 1) % _filteredSongs.length;
    }
    _playSong(_filteredSongs[next], next);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int theme = prefs.getInt('themeIndex') ?? 0;
    bool is3D = prefs.getBool('is3DOn') ?? false;
    bool light = prefs.getBool('isLightMode') ?? false;
    if (mounted) {
      setState(() {
        _themeIndex = theme;
        AppTheme.themeIndex = theme;
        is3DOn = is3D;
        AppTheme.isLightMode = light;
      });
    }
  }

  Future<void> _toggleLightMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        AppTheme.isLightMode = !AppTheme.isLightMode;
      });
    }
    await prefs.setBool('isLightMode', AppTheme.isLightMode);
    _showSnackBar(
      AppTheme.isLightMode ? '☀️ Light Mode ON' : '🌙 Dark Mode ON',
      AppTheme.accent,
    );
  }

  Future<void> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _sortMode = prefs.getInt('sortMode') ?? 0;
      });
    }
    await _applyFilter();
  }

  Future<void> _saveSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortMode', _sortMode);
  }

  Future<void> _toggleTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeIndex', index);
    if (mounted) {
      setState(() {
        _themeIndex = index;
        AppTheme.themeIndex = index;
      });
    }
    const names = ['🟢 Emerald', '🟡 Gold', '🔵 Indigo', '🟣 Purple'];
    _showSnackBar('🎨 ${names[index]} applied', AppTheme.accent);
  }

  Future<void> _toggle3D() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => is3DOn = !is3DOn);
    await prefs.setBool('is3DOn', is3DOn);
    if (is3DOn) {
      if (audioHandler != null) await audioHandler!.setVolume(0.6);
      await _fallbackPlayer.setVolume(0.6);
      _showSnackBar('🎧 Bass Boost ON', AppTheme.accent);
    } else {
      if (audioHandler != null) await audioHandler!.setVolume(1.0);
      await _fallbackPlayer.setVolume(1.0);
      _showSnackBar('🔊 Normal Audio', AppTheme.subText);
    }
  }

  void _toggleShuffleRepeat() {
    setState(() {
      if (!isShuffle && !isRepeat && !isRepeatOne) {
        isShuffle = true;
      } else if (isShuffle) {
        isShuffle = false;
        isRepeat = true;
      } else if (isRepeat) {
        isRepeat = false;
        isRepeatOne = true;
      } else {
        isRepeatOne = false;
        isShuffle = false;
      }
    });
    _showSnackBar(
      isShuffle
          ? '🔀 Shuffle ON'
          : (isRepeat ? '🔁 Repeat All' : (isRepeatOne ? '🔂 Repeat One' : '➡️ Normal')),
      AppTheme.accent,
    );
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      try {
        if (await Permission.audio.isDenied) await Permission.audio.request();
        if (await Permission.storage.isDenied) await Permission.storage.request();
        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }
      } catch (e) {
        debugPrint('⚠️ Permission error: $e');
      }
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
          .where((f) => !_isVoiceNoteFile(f))
          .toList();
      if (mounted) {
        setState(() {
          _songs = songs;
          _filteredSongs = songs;
          _buildFolderMap();
        });
      }
    }
    if (favs != null) {
      if (mounted) setState(() => _favorites = favs);
    }
    if (recent != null) {
      if (mounted) setState(() => _recentSongs = recent);
    }
    if (playlists != null) {
      if (mounted) {
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
  }

  void _buildFolderMap() {
    _songsByFolder.clear();
    for (var song in _songs) {
      String folder = song.parent.path;
      String folderName = folder.split('/').last;
      if (folderName.isEmpty) folderName = 'Root';
      if (!_songsByFolder.containsKey(folderName)) {
        _songsByFolder[folderName] = [];
      }
      _songsByFolder[folderName]!.add(song);
    }

    const callRecKeywords = [
      'call_rec', 'callrec', 'call record', 'callrecord', 'call_recording',
      'sound_recorder', 'voicerecorder', 'voice_recorder', 'recordings',
      'recorder', 'call logs', 'calllog',
    ];

    List<String> sortedKeys = _songsByFolder.keys.toList();

    int getPriority(String folder) {
      String lower = folder.toLowerCase();
      for (String kw in callRecKeywords) {
        if (lower.contains(kw)) return 100;
      }
      List<File> songs = _songsByFolder[folder]!;
      int dateLikeCount = 0;
      for (var s in songs) {
        String name = getSongName(s.path);
        if (RegExp(r'^\d{1,2}\s+\w{3},?\s+\d{1,2}\.\d{2}\s*(am|pm)$',
                caseSensitive: false)
            .hasMatch(name.trim())) {
          dateLikeCount++;
        }
      }
      if (songs.isNotEmpty && dateLikeCount / songs.length > 0.7) return 100;
      return 0;
    }

    sortedKeys.sort((a, b) {
      int pa = getPriority(a);
      int pb = getPriority(b);
      if (pa != pb) return pa.compareTo(pb);
      return _songsByFolder[b]!.length.compareTo(_songsByFolder[a]!.length);
    });

    Map<String, List<File>> sorted = {};
    for (var key in sortedKeys) {
      sorted[key] = _songsByFolder[key]!;
    }
    _songsByFolder = sorted;

    for (var key in _songsByFolder.keys) {
      _songsByFolder[key]!.sort((a, b) {
        String na = getSongName(a.path).toLowerCase();
        String nb = getSongName(b.path).toLowerCase();
        bool aIsRec = _isRecordingName(na);
        bool bIsRec = _isRecordingName(nb);
        if (aIsRec != bIsRec) return aIsRec ? 1 : -1;
        return na.compareTo(nb);
      });
    }
  }

  Future<void> _loadHiddenFolders() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hiddenFolders = prefs.getStringList('hidden_folders') ?? [];
      });
    }
  }

  Future<void> _saveHiddenFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_folders', _hiddenFolders);
  }

  void _removeFolder(String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Remove Folder?', style: TextStyle(color: AppTheme.text)),
        content: Text(
          '"$folderName" list se hata dein?\n\n(Songs phone se delete nahi honge, sirf app mein hide honge)',
          style: TextStyle(color: AppTheme.subText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _hiddenFolders.add(folderName);
                  _hideBanner = false;
                });
              }
              _saveHiddenFolders();
              _applyFilter();
              Navigator.pop(context);
              _showSnackBar('🗑️ "$folderName" removed from list', Colors.orange);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(String folderName, int songCount) {
    bool isHidden = _hiddenFolders.contains(folderName);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.subText,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: AppTheme.primaryGradient),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(folderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppTheme.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text('$songCount songs',
                              style: TextStyle(color: AppTheme.subText, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  isHidden ? Icons.visibility : Icons.visibility_off,
                  color: isHidden ? Colors.green : Colors.orange,
                ),
                title: Text(
                  isHidden ? 'Show Folder' : 'Remove from List',
                  style: TextStyle(color: AppTheme.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isHidden) {
                    if (mounted) setState(() => _hiddenFolders.remove(folderName));
                    _saveHiddenFolders();
                    _applyFilter();
                    _showSnackBar('✅ Folder shown', Colors.green);
                  } else {
                    _removeFolder(folderName);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showHiddenFolders() {
    if (_hiddenFolders.isEmpty) {
      _showSnackBar('Koi hidden folder nahi hai', AppTheme.subText);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.subText,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Hidden Folders',
                    style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ..._hiddenFolders.map((folder) => ListTile(
                leading: const Icon(Icons.folder_off, color: Colors.orange),
                title: Text(folder, style: TextStyle(color: AppTheme.text)),
                trailing: const Icon(Icons.restore, color: Colors.green),
                onTap: () {
                  if (mounted) setState(() => _hiddenFolders.remove(folder));
                  _saveHiddenFolders();
                  _applyFilter();
                  Navigator.pop(context);
                  _showSnackBar('✅ "$folder" restored', Colors.green);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.subText,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.sort, color: AppTheme.text, size: 24),
                    const SizedBox(width: 12),
                    Text('Sort Songs By',
                        style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _sortOption(0, Icons.auto_awesome, 'Smart (Best First)', 'Album art wale upar'),
              _sortOption(1, Icons.sort_by_alpha, 'Title (A-Z)', 'Naam se'),
              _sortOption(2, Icons.access_time, 'Date Added', 'Naye pehle'),
              _sortOption(3, Icons.folder, 'Folder Name', 'Folder se group'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortOption(int index, IconData icon, String title, String subtitle) {
    bool isActive = _sortMode == index;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.accent : AppTheme.subText, size: 22),
      title: Text(title,
          style: TextStyle(
              color: isActive ? AppTheme.accent : AppTheme.text,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.subText, fontSize: 11)),
      trailing: isActive ? Icon(Icons.check_circle, color: AppTheme.accent, size: 22) : null,
      onTap: () async {
        if (mounted) setState(() => _sortMode = index);
        await _saveSortMode();
        await _applyFilter();
        Navigator.pop(context);
        const names = ['Smart', 'Title', 'Date', 'Folder'];
        _showSnackBar('✅ Sorted by ${names[index]}', AppTheme.accent);
      },
    );
  }

  void _buildVideoFolderMap() {
    _videosByFolder.clear();
    for (var video in _videos) {
      String folder = video.parent.path;
      String folderName = folder.split('/').last;
      if (folderName.isEmpty) folderName = 'Root';
      if (!_videosByFolder.containsKey(folderName)) {
        _videosByFolder[folderName] = [];
      }
      _videosByFolder[folderName]!.add(video);
    }
  }

  Future<void> _saveVideos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_videos', _videos.map((f) => f.path).toList());
  }

  Future<void> _loadVideos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedPaths = prefs.getStringList('saved_videos');
    if (savedPaths != null) {
      List<File> videos = savedPaths
          .map((path) => File(path))
          .where((f) => f.existsSync())
          .toList();
      if (mounted) {
        setState(() {
          _videos = videos;
          _buildVideoFolderMap();
        });
      }
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
            .where((f) => !_isVoiceNoteFile(f))
            .toList();
        if (mounted) {
          setState(() {
            for (var song in picked) {
              if (!_songs.any((f) => f.path == song.path)) _songs.add(song);
            }
            _buildFolderMap();
          });
        }
        await _saveSongs();
        await _applyFilter();
        _showSnackBar('✅ ${picked.length} songs added!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('⚠️ Error: $e', Colors.red);
    }
  }

  Future<void> _scanDefaultFolder() async {
    try {
      if (mounted) {
        setState(() {
          _songs.clear();
          _videos.clear();
          _songsByFolder.clear();
          _videosByFolder.clear();
        });
      }

      List<File> allSongs = [];
      List<File> allVideos = [];
      Directory rootDir = Directory('/storage/emulated/0/');

      if (rootDir.existsSync()) {
        try {
          for (var entity in rootDir.listSync(recursive: true)) {
            String path = entity.path.toLowerCase();

            if (path.contains('/android/data/') ||
                path.contains('/android/obb/') ||
                path.contains('/android/media/')) {
              continue;
            }

            if (path.contains('/call_rec/') ||
                path.contains('/callrec/') ||
                path.contains('/call recording/') ||
                path.contains('/callrecordings/') ||
                path.contains('/sound_recorder/') ||
                path.contains('/voicerecorder/') ||
                path.contains('/voice_recorder/') ||
                path.contains('/recordings/') ||
                path.contains('/voice notes/') ||
                path.contains('/whatsapp audio/')) {
              continue;
            }

            if (entity is File) {
              String p = entity.path.toLowerCase();

              bool isAudio = p.endsWith('.mp3') ||
                  p.endsWith('.m4a') ||
                  p.endsWith('.wav') ||
                  p.endsWith('.aac') ||
                  p.endsWith('.flac') ||
                  p.endsWith('.wma') ||
                  p.endsWith('.mp4a');

              if (isAudio && !_isVoiceNoteFile(entity)) {
                allSongs.add(entity);
              }

              if (p.endsWith('.mp4') || p.endsWith('.mkv') || p.endsWith('.avi') ||
                  p.endsWith('.mov') || p.endsWith('.wmv') || p.endsWith('.flv') ||
                  p.endsWith('.webm') || p.endsWith('.m4v') ||
                  p.endsWith('.ts') || p.endsWith('.mpg') || p.endsWith('.mpeg')) {
                allVideos.add(entity);
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Scan error: $e');
        }
      }

      if (mounted) {
        setState(() {
          for (var song in allSongs) {
            if (!_songs.any((f) => f.path == song.path)) _songs.add(song);
          }
          for (var video in allVideos) {
            if (!_videos.any((f) => f.path == video.path)) _videos.add(video);
          }
          _buildFolderMap();
          _buildVideoFolderMap();
        });
      }

      await _saveSongs();
      await _saveVideos();
      await _applyFilter();

      _showSnackBar(
        '✅ ${allSongs.length} songs + ${allVideos.length} videos found!',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('⚠️ Error: $e', Colors.red);
    }
  }

  Future<void> _playSong(File song, int index) async {
    if (_currentSong == song) {
      _togglePlay();
      return;
    }

    if (mounted) {
      setState(() {
        _currentSong = song;
        _currentIndex = index;
        isPlaying = true;
      });
    }
    _isPlayingNotifier.value = true;

    if (!_recentSongs.contains(song.path)) {
      _recentSongs.insert(0, song.path);
      if (_recentSongs.length > 20) _recentSongs.removeLast();
      await _saveRecent();
    }

    if (audioHandler == null) {
      try {
        await _fallbackPlayer.setFilePath(song.path);
        _fallbackPlayer.play();
        _showSnackBar('🎵 Playing: ${getSongName(song.path)}', Colors.green);
      } catch (e) {
        _showSnackBar('⚠️ Play error: $e', Colors.red);
      }
      return;
    }

    List<String> paths;
    if (_selectedFolder != null && _songsByFolder.containsKey(_selectedFolder)) {
      paths = _songsByFolder[_selectedFolder]!.map((f) => f.path).toList();
    } else {
      paths = _filteredSongs.map((f) => f.path).toList();
    }
    await audioHandler!.setQueue(paths, index);
    await audioHandler!.play();

    if (is3DOn) {
      await audioHandler!.setVolume(0.6);
    } else {
      await audioHandler!.setVolume(1.0);
    }

    if (mounted) {
      setState(() => isPlaying = true);
      _isPlayingNotifier.value = true;
    }
  }

  Future<void> _togglePlay() async {
    if (audioHandler == null) {
      if (_fallbackPlayer.playing) {
        await _fallbackPlayer.pause();
      } else {
        await _fallbackPlayer.play();
      }
      return;
    }
    if (isPlaying) {
      await audioHandler!.pause();
    } else {
      await audioHandler!.play();
    }
  }

  void _playNext() {
    if (audioHandler == null) {
      _playNextFallback();
      return;
    }
    audioHandler!.skipToNext();
  }

  void _playPrevious() {
    if (audioHandler == null) {
      if (_filteredSongs.isEmpty) return;
      final prev = _currentIndex > 0 ? _currentIndex - 1 : _filteredSongs.length - 1;
      _playSong(_filteredSongs[prev], prev);
      return;
    }
    audioHandler!.skipToPrevious();
  }

  Future<void> _applyFilter() async {
    List<File> sourceSongs = _visibleSongs;
    List<File> baseList = [];

    if (_selectedTab == 0) {
      baseList = List.from(sourceSongs);

      if (_sortMode == 0) {
        List<File> musicList = [];
        List<File> recList = [];

        for (var song in baseList) {
          String name = getSongName(song.path);
          if (_isRecordingName(name) || _isVoiceNoteFile(song)) {
            recList.add(song);
          } else {
            musicList.add(song);
          }
        }

        int alphaSort(File a, File b) => getSongName(a.path)
            .toLowerCase()
            .compareTo(getSongName(b.path).toLowerCase());

        musicList.sort(alphaSort);
        recList.sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (e) {
            return 0;
          }
        });

        baseList = [...musicList, ...recList];
      } else if (_sortMode == 1) {
        baseList.sort((a, b) =>
            getSongName(a.path).toLowerCase().compareTo(getSongName(b.path).toLowerCase()));
      } else if (_sortMode == 2) {
        baseList.sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (e) {
            return 0;
          }
        });
      } else if (_sortMode == 3) {
        baseList.sort((a, b) {
          String fa = a.parent.path.split('/').last.toLowerCase();
          String fb = b.parent.path.split('/').last.toLowerCase();
          if (fa == fb) {
            return getSongName(a.path).toLowerCase().compareTo(getSongName(b.path).toLowerCase());
          }
          return fa.compareTo(fb);
        });
      }
    } else if (_selectedTab == 1) {
      baseList = sourceSongs.where((f) => _favorites.contains(f.path)).toList();
    } else if (_selectedTab == 2) {
      baseList = _recentSongs
          .map((path) => File(path))
          .where((f) => f.existsSync() && !_isSongInHiddenFolder(f))
          .toList();
    } else if (_selectedTab == 3 && _openedPlaylist != null) {
      var playlist = _playlists.firstWhere(
        (p) => p['name'] == _openedPlaylist,
        orElse: () => {'name': '', 'songs': <String>[]},
      );
      List<String> paths = (playlist['songs'] as List<String>);
      baseList = sourceSongs.where((f) => paths.contains(f.path)).toList();
    }

    String query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      baseList = baseList
          .where((f) => getSongName(f.path).toLowerCase().contains(query))
          .toList();
    }
    if (mounted) setState(() => _filteredSongs = baseList);
  }

  void _deleteSongPermanently(File song) {
    if (mounted) {
      setState(() {
        if (song == _currentSong) {
          if (audioHandler != null) audioHandler!.stop();
          _fallbackPlayer.stop();
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
        _buildFolderMap();
      });
    }
    _saveSongs();
    _saveFavorites();
    _saveRecent();
    _savePlaylists();
    _applyFilter();
    _showSnackBar('🗑️ Song deleted', Colors.red);
  }

  void _removeFromPlaylist(File song) {
    if (_openedPlaylist == null) return;
    if (mounted) {
      setState(() {
        var playlist = _playlists.firstWhere((p) => p['name'] == _openedPlaylist);
        (playlist['songs'] as List<String>).remove(song.path);
      });
    }
    _savePlaylists();
    _applyFilter();
    _showSnackBar('🚫 Removed from $_openedPlaylist', Colors.orange);
  }

  void _toggleFavorite(File song) {
    if (mounted) {
      setState(() {
        if (_favorites.contains(song.path)) {
          _favorites.remove(song.path);
          _showSnackBar('💔 Removed from Favorites', Colors.orange);
        } else {
          _favorites.add(song.path);
          _showSnackBar('❤️ Added to Favorites', Colors.pink);
        }
      });
    }
    _saveFavorites();
    _applyFilter();
  }

  void _showAddToPlaylist(File song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50, height: 5,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppTheme.subText,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Add to Playlist',
                    style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No playlists yet!',
                      style: TextStyle(color: AppTheme.subText)),
                )
              else
                ..._playlists.map((playlist) {
                  bool isIn = (playlist['songs'] as List<String>).contains(song.path);
                  return ListTile(
                    title: Text(playlist['name'],
                        style: TextStyle(color: AppTheme.text)),
                    trailing: isIn ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          if (isIn) {
                            (playlist['songs'] as List<String>).remove(song.path);
                          } else {
                            (playlist['songs'] as List<String>).add(song.path);
                          }
                        });
                      }
                      _savePlaylists();
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
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
                    child: const Center(
                      child: Text('Create New Playlist',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewPlaylist(File song) {
    TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('New Playlist', style: TextStyle(color: AppTheme.text)),
        content: TextField(
          controller: nameCtrl,
          style: TextStyle(color: AppTheme.text),
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                if (mounted) {
                  setState(() {
                    _playlists.add({'name': nameCtrl.text.trim(), 'songs': [song.path]});
                  });
                }
                _savePlaylists();
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showMainSongOptions(File song) {
    bool isFav = _favorites.contains(song.path);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionsSheet(
        title: getSongName(song.path),
        songPath: song.path,
        options: [
          _optionItem(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            color: Colors.pinkAccent,
            title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
            onTap: () { Navigator.pop(context); _toggleFavorite(song); },
          ),
          _optionItem(
            icon: Icons.playlist_add,
            color: AppTheme.accent,
            title: 'Add to Playlist',
            onTap: () { Navigator.pop(context); _showAddToPlaylist(song); },
          ),
          _optionItem(
            icon: Icons.delete_forever,
            color: Colors.redAccent,
            title: 'Delete Permanently',
            onTap: () { Navigator.pop(context); _confirmDelete(song); },
          ),
        ],
      ),
    );
  }

  void _showPlaylistSongOptions(File song) {
    bool isFav = _favorites.contains(song.path);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionsSheet(
        title: getSongName(song.path),
        songPath: song.path,
        options: [
          _optionItem(
            icon: Icons.remove_circle_outline,
            color: Colors.orange,
            title: 'Remove from Playlist',
            onTap: () { Navigator.pop(context); _removeFromPlaylist(song); },
          ),
          _optionItem(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            color: Colors.pinkAccent,
            title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
            onTap: () { Navigator.pop(context); _toggleFavorite(song); },
          ),
          _optionItem(
            icon: Icons.delete_forever,
            color: Colors.redAccent,
            title: 'Delete Permanently',
            onTap: () { Navigator.pop(context); _confirmDelete(song); },
          ),
        ],
      ),
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
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AlbumArtWidget(audioPath: songPath, size: 55, isPlaying: false),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
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
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: AppTheme.text)),
      onTap: onTap,
    );
  }

  void _confirmDelete(File song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Delete?', style: TextStyle(color: AppTheme.text)),
        content: Text('Delete "${getSongName(song.path)}"?',
            style: TextStyle(color: AppTheme.subText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () { Navigator.pop(context); _deleteSongPermanently(song); },
            child: const Text('Delete'),
          ),
        ],
      ),
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

    int mp3Index = name.toUpperCase().indexOf('(MP3');
    if (mp3Index == -1) mp3Index = name.toUpperCase().indexOf('[MP3');
    if (mp3Index == -1) mp3Index = name.toUpperCase().indexOf('(320K');
    if (mp3Index == -1) mp3Index = name.toUpperCase().indexOf('(128K');
    if (mp3Index == -1) mp3Index = name.toUpperCase().indexOf('(192K');
    if (mp3Index == -1) mp3Index = name.toUpperCase().indexOf('(256K');
    if (mp3Index == -1) mp3Index = name.toUpperCase().indexOf('[320K');
    if (mp3Index != -1) {
      name = name.substring(0, mp3Index);
    }

    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    name = name.replaceAll('_', ' ').trim();
    return name;
  }

  void _showQueueSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: 50, height: 5,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppTheme.subText,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.queue_music, color: AppTheme.text, size: 28),
                    const SizedBox(width: 12),
                    Text('Up Next',
                        style: TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${_filteredSongs.length} songs',
                        style: TextStyle(color: AppTheme.subText, fontSize: 14)),
                  ],
                ),
              ),
              Divider(color: AppTheme.subText.withOpacity(0.2), height: 1),
              Expanded(
                child: _filteredSongs.isEmpty
                    ? Center(
                        child: Text('Queue is empty',
                            style: TextStyle(color: AppTheme.subText)),
                      )
                    : ListView.builder(
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = _filteredSongs[index];
                          final isCurrent = _currentSong == song;
                          return ListTile(
                            leading: AlbumArtWidget(
                              audioPath: song.path,
                              size: 45,
                              isPlaying: isCurrent && isPlaying,
                            ),
                            title: Text(
                              getSongName(song.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? AppTheme.accent : AppTheme.text,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              isCurrent ? 'Now Playing' : 'Local Audio',
                              style: TextStyle(
                                color: isCurrent ? AppTheme.accent : AppTheme.subText,
                                fontSize: 11,
                              ),
                            ),
                            trailing: isCurrent
                                ? Icon(Icons.graphic_eq, color: AppTheme.accent, size: 20)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _playSong(song, index);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.bg, AppTheme.card]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: AppTheme.text, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text('Now Playing',
                          style: TextStyle(
                              color: AppTheme.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(
                          _favorites.contains(_currentSong!.path)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favorites.contains(_currentSong!.path)
                              ? Colors.pinkAccent
                              : AppTheme.text,
                          size: 26,
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
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AlbumArtWidget(
                    audioPath: _currentSong!.path,
                    size: 250,
                    isPlaying: isPlaying,
                    isCircle: false,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  getSongName(_currentSong!.path),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                StreamBuilder<Duration>(
                  stream: audioHandler != null
                      ? audioHandler!.positionStream
                      : _fallbackPlayer.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final maxDur = _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0;
                    final val = pos.inSeconds.toDouble().clamp(0.0, maxDur);
                    return Column(
                      children: [
                        Slider(
                          value: val,
                          max: maxDur,
                          activeColor: AppTheme.primaryGradient[1],
                          onChanged: (value) async {
                            final target = Duration(seconds: value.toInt());
                            if (audioHandler != null) {
                              await audioHandler!.seek(target);
                            } else {
                              await _fallbackPlayer.seek(target);
                            }
                            setModalState(() {});
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatTime(pos),
                                  style: TextStyle(color: AppTheme.subText, fontSize: 12)),
                              Text(formatTime(_duration),
                                  style: TextStyle(color: AppTheme.subText, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          isShuffle
                              ? Icons.shuffle
                              : (isRepeatOne
                                  ? Icons.repeat_one
                                  : (isRepeat ? Icons.repeat : Icons.shuffle)),
                          color: (isShuffle || isRepeat || isRepeatOne)
                              ? AppTheme.primaryGradient[1]
                              : AppTheme.subText,
                          size: 26,
                        ),
                        onPressed: () {
                          _toggleShuffleRepeat();
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous,
                            color: AppTheme.text, size: 45),
                        onPressed: () {
                          _playPrevious();
                          setModalState(() {});
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isPlayingNotifier,
                        builder: (context, playing, child) => Container(
                          height: 75,
                          width: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: AppTheme.primaryGradient),
                          ),
                          child: IconButton(
                            iconSize: 45,
                            color: Colors.white,
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                            onPressed: _togglePlay,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next,
                            color: AppTheme.text, size: 45),
                        onPressed: () {
                          _playNext();
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.queue_music,
                            color: AppTheme.subText, size: 26),
                        onPressed: () => _showQueueSheet(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(int index, String name, String emoji, List<Color> gradient) {
    bool isActive = _themeIndex == index;
    return GestureDetector(
      onTap: () => _toggleTheme(index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppTheme.accent : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(isActive ? Icons.check_circle : Icons.circle_outlined, color: Colors.white, size: 18),
            const SizedBox(height: 5),
            Text('$emoji $name', textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.bg,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.bg, AppTheme.card])),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bhai Bhai Music',
                        style: TextStyle(color: AppTheme.text, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('Local Music Player', style: TextStyle(color: AppTheme.subText, fontSize: 13)),
                  ],
                ),
              ),
              Divider(color: AppTheme.subText.withOpacity(0.2), height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _drawerItem(
                      icon: Icons.library_music, iconColor: Colors.cyan,
                      title: 'Pick Songs', subtitle: 'Select from storage',
                      onTap: () { Navigator.pop(context); _pickSongs(); },
                    ),
                    _drawerItem(
                      icon: Icons.folder_open, iconColor: AppTheme.accent,
                      title: 'Scan Music', subtitle: 'Auto scan folders',
                      onTap: () { Navigator.pop(context); _scanDefaultFolder(); },
                    ),
                    _drawerItem(
                      icon: Icons.favorite, iconColor: Colors.pinkAccent,
                      title: 'Favorites', subtitle: '${_favorites.length} songs',
                      onTap: () {
                        Navigator.pop(context);
                        if (mounted) setState(() { _selectedTab = 1; });
                        _applyFilter();
                      },
                    ),
                    _drawerItem(
                      icon: Icons.history, iconColor: Colors.orangeAccent,
                      title: 'Recent', subtitle: '${_recentSongs.length} songs',
                      onTap: () {
                        Navigator.pop(context);
                        if (mounted) setState(() { _selectedTab = 2; });
                        _applyFilter();
                      },
                    ),
                    _drawerItem(
                      icon: Icons.visibility_off, iconColor: Colors.orange,
                      title: 'Hidden Folders', subtitle: '${_hiddenFolders.length} folder(s)',
                      onTap: () {
                        Navigator.pop(context);
                        _showHiddenFolders();
                      },
                    ),
                    _drawerItem(
                      icon: Icons.graphic_eq, iconColor: Colors.deepPurpleAccent,
                      title: 'Enhance Sound', subtitle: 'Bass & Immersive',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnhanceSoundScreen(
                              isDarkTheme: !AppTheme.isLightMode,
                              onEffectsChanged: (bass, immersive) {},
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(color: AppTheme.subText.withOpacity(0.2), height: 1),
                    ListTile(
                      leading: Icon(
                        AppTheme.isLightMode ? Icons.dark_mode : Icons.light_mode,
                        color: AppTheme.accent,
                      ),
                      title: Text(
                        AppTheme.isLightMode ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(color: AppTheme.text),
                      ),
                      trailing: Switch(
                        value: AppTheme.isLightMode,
                        onChanged: (value) => _toggleLightMode(),
                        activeColor: AppTheme.accent,
                      ),
                    ),
                    ListTile(
                      leading: Icon(is3DOn ? Icons.surround_sound : Icons.surround_sound_outlined,
                          color: is3DOn ? AppTheme.accent : AppTheme.subText),
                      title: Text('3D Audio', style: TextStyle(color: AppTheme.text)),
                      trailing: Switch(
                        value: is3DOn,
                        onChanged: (value) => _toggle3D(),
                        activeColor: AppTheme.accent,
                      ),
                    ),
                    Divider(color: AppTheme.subText.withOpacity(0.2), height: 1),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎨 Choose Theme',
                              style: TextStyle(color: AppTheme.text, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildThemeCard(0, 'Emerald', '🟢', AppColors.gradient0)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildThemeCard(1, 'Gold', '🟡', AppColors.gradient1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildThemeCard(2, 'Indigo', '🔵', AppColors.gradient2)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildThemeCard(3, 'Purple', '🟣', AppColors.gradient3)),
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
                child: Text("Version 1.0.0\nMade with ❤️ by Bhai Bhai",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.subText, fontSize: 11)),
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
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.subText, fontSize: 11)),
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
          gradient: LinearGradient(colors: AppTheme.primaryGradient),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AlbumArtWidget(audioPath: _currentSong!.path, size: 40, isPlaying: isPlaying),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(getSongName(_currentSong!.path),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
                  onPressed: _playPrevious, padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlayingNotifier,
                  builder: (context, playing, child) => IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white, size: 38),
                    onPressed: _togglePlay, padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
                  onPressed: _playNext, padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedTab = index;
              _openedPlaylist = null;
              _selectedFolder = null;
              _selectedVideoFolder = null;
            });
          }
          _applyFilter();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: isActive ? LinearGradient(colors: AppTheme.primaryGradient) : null,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.subText,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 10)),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsView() {
    if (_openedPlaylist != null) {
      var playlist = _playlists.firstWhere((p) => p['name'] == _openedPlaylist,
          orElse: () => {'name': '', 'songs': <String>[]});
      int count = (playlist['songs'] as List<String>).length;

      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.primaryGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _openedPlaylist = null),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_openedPlaylist!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('$count songs', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredSongs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) =>
                        _buildSongTile(_filteredSongs[index], index, isFromPlaylist: true),
                  ),
          ),
        ],
      );
    }

    if (_playlists.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        var playlist = _playlists[index];
        int count = (playlist['songs'] as List<String>).length;
        return GestureDetector(
          onTap: () {
            if (mounted) setState(() { _openedPlaylist = playlist['name']; });
            _applyFilter();
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.primaryGradient.map((c) => c.withOpacity(0.3)).toList()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.playlist_play, color: Colors.white, size: 28),
                Text(playlist['name'], maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoldersView() {
    Map<String, List<File>> visibleFolders = Map.fromEntries(
      _songsByFolder.entries
          .where((e) => !_hiddenFolders.contains(e.key)),
    );

    if (visibleFolders.isEmpty) {
      return _buildEmptyState();
    }

    if (_selectedFolder != null) {
      List<File> folderSongs = _songsByFolder[_selectedFolder] ?? [];
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.primaryGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedFolder = null),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedFolder!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('${folderSongs.length} songs',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showFolderOptions(_selectedFolder!, folderSongs.length),
                ),
              ],
            ),
          ),
          Expanded(
            child: folderSongs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: folderSongs.length,
                    itemBuilder: (context, index) => _buildFolderSongTile(
                      folderSongs[index],
                      index,
                      folderSongs,
                    ),
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_hiddenFolders.isNotEmpty && !_hideBanner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_off, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showHiddenFolders,
                      child: Text(
                        '${_hiddenFolders.length} hidden folder(s) — tap to restore',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _hideBanner = true),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.orange, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: visibleFolders.length,
            itemBuilder: (context, index) {
              String folderName = visibleFolders.keys.elementAt(index);
              List<File> folderSongs = visibleFolders[folderName]!;
              return GestureDetector(
                onTap: () => setState(() => _selectedFolder = folderName),
                onLongPress: () => _showFolderOptions(folderName, folderSongs.length),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient.map((c) => c.withOpacity(0.3)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.primaryGradient[0].withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: AppTheme.primaryGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(folderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AppTheme.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${folderSongs.length} songs',
                                style: TextStyle(color: AppTheme.subText, fontSize: 12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showFolderOptions(folderName, folderSongs.length),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.more_vert, color: AppTheme.subText, size: 20),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: AppTheme.subText, size: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideosView() {
    if (_selectedVideoFolder != null) {
      List<File> folderVideos = _videosByFolder[_selectedVideoFolder] ?? [];

      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.primaryGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedVideoFolder = null),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedVideoFolder!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('${folderVideos.length} videos',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: folderVideos.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: folderVideos.length,
                    itemBuilder: (context, index) =>
                        _buildVideoTile(folderVideos, index),
                  ),
          ),
        ],
      );
    }

    if (_videosByFolder.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _videosByFolder.length,
      itemBuilder: (context, index) {
        String folderName = _videosByFolder.keys.elementAt(index);
        List<File> folderVideos = _videosByFolder[folderName]!;

        return GestureDetector(
          onTap: () => setState(() => _selectedVideoFolder = folderName),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient
                    .map((c) => c.withOpacity(0.3))
                    .toList(),
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: AppTheme.primaryGradient[0].withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.video_library,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${folderVideos.length} videos',
                          style: TextStyle(
                              color: AppTheme.subText, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: AppTheme.subText, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoTile(List<File> folderVideos, int index) {
    final video = folderVideos[index];
    final videoName = video.path.split('/').last;
    final sizeMB = (video.lengthSync() / (1024 * 1024)).toStringAsFixed(1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoFile: video,
              videoList: folderVideos,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.isLightMode
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppTheme.primaryGradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_fill,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.text, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sizeMB MB',
                    style: TextStyle(
                        color: AppTheme.subText, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.subText, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 80, color: AppTheme.subText),
          const SizedBox(height: 20),
          Text('No songs found!',
              style: TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Open menu → Pick Songs or Scan',
              style: TextStyle(color: AppTheme.subText, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSongTile(File song, int index, {bool isFromPlaylist = false}) {
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: AppTheme.primaryGradient) : null,
          color: isSelected
              ? null
              : (AppTheme.isLightMode
                  ? Colors.black.withOpacity(0.04)
                  : Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            AlbumArtWidget(audioPath: song.path, size: 45, isPlaying: isSelected && isPlaying),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isSelected && isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PlayingIndicator(color: isSelected ? Colors.white : AppTheme.accent),
                        ),
                      Expanded(
                        child: Text(
                          getSongName(song.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isFav) ...[
                        const Icon(Icons.favorite, color: Colors.pinkAccent, size: 11),
                        const SizedBox(width: 4),
                      ],
                      Text(isSelected && isPlaying ? 'Now Playing' : 'Local Audio',
                          style: TextStyle(
                              color: isSelected ? Colors.white70 : AppTheme.subText,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              ValueListenableBuilder<bool>(
                valueListenable: _isPlayingNotifier,
                builder: (context, playing, child) => IconButton(
                  icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white, size: 32),
                  onPressed: _togglePlay,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSongTile(File song, int index, List<File> folderSongs) {
    bool isSelected = _currentSong == song;
    bool isFav = _favorites.contains(song.path);

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _filteredSongs = folderSongs;
            _currentIndex = index;
          });
        }
        _playSong(song, index);
      },
      onLongPress: () => _showMainSongOptions(song),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: AppTheme.primaryGradient) : null,
          color: isSelected
              ? null
              : (AppTheme.isLightMode
                  ? Colors.black.withOpacity(0.04)
                  : Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            AlbumArtWidget(audioPath: song.path, size: 45, isPlaying: isSelected && isPlaying),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isSelected && isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PlayingIndicator(color: isSelected ? Colors.white : AppTheme.accent),
                        ),
                      Expanded(
                        child: Text(
                          getSongName(song.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isFav) ...[
                        const Icon(Icons.favorite, color: Colors.pinkAccent, size: 11),
                        const SizedBox(width: 4),
                      ],
                      Text(isSelected && isPlaying ? 'Now Playing' : 'Local Audio',
                          style: TextStyle(
                              color: isSelected ? Colors.white70 : AppTheme.subText,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              ValueListenableBuilder<bool>(
                valueListenable: _isPlayingNotifier,
                builder: (context, playing, child) => IconButton(
                  icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white, size: 32),
                  onPressed: _togglePlay,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isPlayingNotifier.dispose();
    _searchController.dispose();
    _fallbackPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.bg, AppTheme.card])),
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
                        child: Icon(Icons.menu, color: AppTheme.text, size: 22),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bhai Bhai Music',
                              style: TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Feel The Rhythm', style: TextStyle(color: AppTheme.subText, fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleLightMode,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          AppTheme.isLightMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppTheme.accent,
                          size: 24,
                        ),
                      ),
                    ),
                    if (_selectedTab == 0)
                      GestureDetector(
                        onTap: _showSortOptions,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.sort,
                            color: _sortMode != 0 ? AppTheme.accent : AppTheme.text.withOpacity(0.7),
                            size: 24,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _toggle3D,
                      child: Icon(
                        is3DOn ? Icons.surround_sound : Icons.surround_sound_outlined,
                        color: is3DOn ? AppTheme.accent : AppTheme.text.withOpacity(0.7), size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  style: TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    hintStyle: TextStyle(color: AppTheme.subText),
                    prefixIcon: Icon(Icons.search, color: AppTheme.subText),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.subText.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTab(0, '🎵 All'),
                    _buildTab(1, '❤️ Fav'),
                    _buildTab(2, '🕒 Recent'),
                    _buildTab(3, '📁 Playlists'),
                    _buildTab(4, '🗂️ Folders'),
                    _buildTab(5, '🎬 Videos'),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: _selectedTab == 3
                    ? _buildPlaylistsView()
                    : _selectedTab == 4
                        ? _buildFoldersView()
                        : _selectedTab == 5
                            ? _buildVideosView()
                            : _filteredSongs.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    itemCount: _filteredSongs.length,
                                    itemBuilder: (context, index) => _buildSongTile(_filteredSongs[index], index),
                                  ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _currentSong != null
          ? Container(
              color: AppTheme.bg,
              child: SafeArea(
                top: false,
                child: _buildSlimMiniPlayer(),
              ),
            )
          : Container(color: AppTheme.bg),
    );
  }
}

// ✅ Playing Indicator (animated bars)
class _PlayingIndicator extends StatefulWidget {
  final Color color;
  const _PlayingIndicator({required this.color});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (index) {
              final heights = [0.5, 1.0, 0.7];
              final animatedHeight = heights[index] * _controller.value;
              return Container(
                width: 3,
                height: 14 * animatedHeight.clamp(0.3, 1.0),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
