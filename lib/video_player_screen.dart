import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  final List<File>? videoList;
  final int? initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
    this.videoList,
    this.initialIndex,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  // ✅ Auto-Play Next Video
  List<File> _playlist = [];
  int _currentIndex = 0;

  // ✅ Brightness & Volume
  double _brightness = 0.5;
  double _volume = 1.0;

  // ✅ Stretch Scale
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _baseScaleX = 1.0;
  double _baseScaleY = 1.0;

  // ✅ Gesture
  double _gestureStartX = 0;
  double _gestureStartY = 0;
  double _gestureStartVolume = 1.0;
  double _gestureStartBrightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  // ✅ UI
  bool _showTitle = true;
  Timer? _titleTimer;
  double _playbackSpeed = 1.0;
  double _aspectRatio = 1.0;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();

    // ✅ Playlist setup
    _playlist = widget.videoList ?? [widget.videoFile];
    _currentIndex = widget.initialIndex ?? 0;

    _initializePlayer();
    _initBrightness();
    _startTitleTimer();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initBrightness() async {
    try {
      _brightness = await ScreenBrightness().application;
      setState(() {});
    } catch (e) {
      debugPrint('Brightness init error: $e');
    }
  }

  void _startTitleTimer() {
    _titleTimer?.cancel();
    setState(() => _showTitle = true);
    _titleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTitle = false);
    });
  }

  void _recreateChewieController() {
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: _isLooping,
      aspectRatio: _aspectRatio,
      allowFullScreen: false,
      allowMuting: true,
      showControls: true,
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF34D399),
        handleColor: const Color(0xFF34D399),
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightGreen,
      ),
    );
  }

  Future<void> _initializePlayer() async {
    try {
      final fileToPlay = _playlist.isNotEmpty
          ? _playlist[_currentIndex]
          : widget.videoFile;

      _videoController = VideoPlayerController.file(fileToPlay);
      await _videoController.initialize();
      _videoController.addListener(_videoListener);

      _aspectRatio = _videoController.value.aspectRatio;
      _recreateChewieController();

      setState(() {});
    } catch (e) {
      debugPrint('❌ Video init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Video play error: $e')),
        );
      }
    }
  }

  // ✅ Video complete listener
  void _videoListener() {
    if (_videoController.value.position >=
            _videoController.value.duration &&
        _videoController.value.duration.inSeconds > 0 &&
        !_videoController.value.isPlaying) {
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    if (_playlist.isEmpty || _currentIndex >= _playlist.length - 1) {
      _showSnackBar('✅ All videos completed');
      return;
    }

    setState(() {
      _currentIndex++;
    });
    _playCurrentVideo();
  }

  void _playPreviousVideo() {
    if (_playlist.isEmpty || _currentIndex <= 0) return;

    setState(() {
      _currentIndex--;
    });
    _playCurrentVideo();
  }

  Future<void> _playCurrentVideo() async {
    try {
      _videoController.removeListener(_videoListener);
      await _videoController.dispose();
      _chewieController?.dispose();

      final fileToPlay = _playlist[_currentIndex];
      _videoController = VideoPlayerController.file(fileToPlay);
      await _videoController.initialize();
      _videoController.addListener(_videoListener);

      _aspectRatio = _videoController.value.aspectRatio;
      _recreateChewieController();

      setState(() {});
      _startTitleTimer();
    } catch (e) {
      debugPrint('❌ Next video error: $e');
    }
  }

  Future<void> _setBrightness(double value) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(value);
      setState(() => _brightness = value.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Brightness set error: $e');
    }
  }

  Future<void> _setVolume(double value) async {
    try {
      double targetVol = value.clamp(0.0, 2.0);
      await _videoController.setVolume(targetVol > 1.0 ? 1.0 : targetVol);
      setState(() => _volume = targetVol);
    } catch (e) {
      debugPrint('Volume set error: $e');
    }
  }

  void _onGestureStart(DragStartDetails details, Size screenSize) {
    _gestureStartX = details.localPosition.dx;
    _gestureStartY = details.localPosition.dy;
    _gestureStartVolume = _volume;
    _gestureStartBrightness = _brightness;
  }

  void _onGestureUpdate(DragUpdateDetails details, Size screenSize) {
    bool isLeftSide = _gestureStartX < screenSize.width / 2;

    if (isLeftSide) {
      double delta =
          (details.localPosition.dy - _gestureStartY) / (screenSize.height * 0.7);
      double newVolume = (_gestureStartVolume - delta).clamp(0.0, 2.0);
      _setVolume(newVolume);
      setState(() {
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      });
    } else {
      double delta =
          (details.localPosition.dy - _gestureStartY) / (screenSize.height * 0.7);
      double newBrightness =
          (_gestureStartBrightness - delta).clamp(0.0, 1.0);
      _setBrightness(newBrightness);
      setState(() {
        _showBrightnessIndicator = true;
        _showVolumeIndicator = false;
      });
    }
  }

  void _onGestureEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF34D399),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVolumeSheet() {
    _startTitleTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Volume Boost (Max 200%)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.volume_mute, color: Colors.white, size: 22),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 2.0,
                      activeColor: const Color(0xFF34D399),
                      inactiveColor: Colors.grey.shade700,
                      onChanged: (value) {
                        _setVolume(value);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white, size: 22),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Volume: ${(_volume * 100).toInt()}%',
                style: TextStyle(
                    color: _volume > 1.0 ? Colors.orangeAccent : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        _volume > 1.0 ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrightnessSheet() {
    _startTitleTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.brightness_low, color: Colors.white, size: 22),
                  Expanded(
                    child: Slider(
                      value: _brightness,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF34D399),
                      inactiveColor: Colors.grey.shade700,
                      onChanged: (value) {
                        _setBrightness(value);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const Icon(Icons.brightness_high, color: Colors.white, size: 22),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Brightness: ${(_brightness * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedSheet() {
    _startTitleTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'Playback Speed',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              bool isSelected = _playbackSpeed == speed;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFF34D399) : Colors.white54,
                ),
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF34D399) : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  _videoController.setPlaybackSpeed(speed);
                  setState(() => _playbackSpeed = speed);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showAspectRatioSheet() {
    _startTitleTimer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'Aspect Ratio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            ListTile(
              leading: const Icon(Icons.crop_original, color: Colors.white),
              title: const Text('Fit (Original)',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _scaleX = 1.0;
                  _scaleY = 1.0;
                  _aspectRatio = _videoController.value.aspectRatio;
                  _recreateChewieController();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_free, color: Colors.white),
              title: const Text('Fill (Cover)',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _scaleX = 1.0;
                  _scaleY = 1.0;
                  _aspectRatio = MediaQuery.of(context).size.aspectRatio;
                  _recreateChewieController();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fullscreen, color: Colors.white),
              title: const Text('Stretch (16:9)',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _scaleX = 1.0;
                  _scaleY = 1.0;
                  _aspectRatio = 16 / 9;
                  _recreateChewieController();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLoop() {
    _startTitleTimer();
    setState(() {
      _isLooping = !_isLooping;
      _recreateChewieController();
    });
    _showSnackBar(_isLooping ? '🔁 Loop ON' : '➡️ Loop OFF');
  }

  Future<void> _toggleFullscreen() async {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() {
        _aspectRatio = MediaQuery.of(context).size.aspectRatio;
        _recreateChewieController();
      });
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      setState(() {
        _aspectRatio = _videoController.value.aspectRatio;
        _recreateChewieController();
      });
    }
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _chewieController?.dispose();
    ScreenBrightness().resetApplicationScreenBrightness();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) => _startTitleTimer(),
        behavior: HitTestBehavior.translucent,
        child: GestureDetector(
          onScaleStart: (details) {
            _baseScaleX = _scaleX;
            _baseScaleY = _scaleY;
          },
          onScaleUpdate: (details) {
            if (details.scale != 1.0 ||
                details.horizontalScale != 1.0 ||
                details.verticalScale != 1.0) {
              setState(() {
                _scaleX = (_baseScaleX * details.horizontalScale).clamp(0.5, 3.0);
                _scaleY = (_baseScaleY * details.verticalScale).clamp(0.5, 3.0);
              });
            }
          },
          onPanStart: (details) => _onGestureStart(details, screenSize),
          onPanUpdate: (details) => _onGestureUpdate(details, screenSize),
          onPanEnd: _onGestureEnd,
          child: Stack(
            children: [
              Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(_scaleX, _scaleY, 1.0),
                  child: _chewieController != null &&
                          _chewieController!
                              .videoPlayerController.value.isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator(
                          color: Color(0xFF34D399)),
                ),
              ),

              // ✅ Top Overlay (AppBar bina Next/Prev button ke)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showTitle,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black87, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        iconTheme: const IconThemeData(color: Colors.white),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _playlist.isNotEmpty
                                  ? _playlist[_currentIndex]
                                      .path
                                      .split('/')
                                      .last
                                  : widget.videoFile.path.split('/').last,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_playlist.length > 1)
                              Text(
                                'Video ${_currentIndex + 1} of ${_playlist.length}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.speed, color: Colors.white),
                            onPressed: _showSpeedSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.aspect_ratio,
                                color: Colors.white),
                            onPressed: _showAspectRatioSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: Icon(
                              _isLooping ? Icons.repeat_one : Icons.repeat,
                              color: _isLooping
                                  ? const Color(0xFF34D399)
                                  : Colors.white,
                            ),
                            onPressed: _toggleLoop,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.brightness_6,
                                color: Colors.white),
                            onPressed: _showBrightnessSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.volume_up,
                                color: Colors.white),
                            onPressed: _showVolumeSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.fullscreen,
                                color: Colors.white),
                            onPressed: _toggleFullscreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ New: Centered Left & Right Previous/Next Buttons 
              if (_playlist.length > 1)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _showTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showTitle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Button (Left Side)
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54, // Halke black color ka background
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 35,
                                icon: Icon(
                                  Icons.skip_previous,
                                  color: _currentIndex > 0 ? Colors.white : Colors.white38,
                                ),
                                onPressed: _currentIndex > 0 ? _playPreviousVideo : null,
                              ),
                            ),
                          ),
                          // Next Button (Right Side)
                          Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54, // Halke black color ka background
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 35,
                                icon: Icon(
                                  Icons.skip_next,
                                  color: _currentIndex < _playlist.length - 1 ? Colors.white : Colors.white38,
                                ),
                                onPressed: _currentIndex < _playlist.length - 1 ? _playNextVideo : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ✅ Volume Overlay
              if (_showVolumeIndicator)
                Positioned(
                  left: 20,
                  top: screenSize.height * 0.25,
                  child: Container(
                    width: 45,
                    height: 180,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          _volume == 0
                              ? Icons.volume_off
                              : _volume > 1.0
                                  ? Icons.volume_up_outlined
                                  : Icons.volume_up,
                          color: _volume > 1.0
                              ? Colors.orangeAccent
                              : Colors.white,
                          size: 20,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: LinearProgressIndicator(
                                value: _volume / 2.0,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _volume > 1.0
                                      ? Colors.orangeAccent
                                      : const Color(0xFF34D399),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${(_volume * 100).toInt()}%',
                          style: TextStyle(
                            color: _volume > 1.0
                                ? Colors.orangeAccent
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ✅ Brightness Overlay
              if (_showBrightnessIndicator)
                Positioned(
                  right: 20,
                  top: screenSize.height * 0.25,
                  child: Container(
                    width: 45,
                    height: 180,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.brightness_6,
                            color: Colors.white, size: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: LinearProgressIndicator(
                                value: _brightness,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF34D399)),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${(_brightness * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ✅ Stretch Reset Button
              if (_scaleX != 1.0 || _scaleY != 1.0)
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _scaleX = 1.0;
                        _scaleY = 1.0;
                      });
                      _showSnackBar('↩️ Stretch Reset');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.restore,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
