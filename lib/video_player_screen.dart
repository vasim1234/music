import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  // ✅ Stretch Scale & Aspect Ratio Fix
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _baseScaleX = 1.0;
  double _baseScaleY = 1.0;
  String _aspectRatioMode = "Original"; // "Original", "Fill", "Stretch"

  // ✅ Gesture
  double _gestureStartX = 0;
  double _gestureStartY = 0;
  double _gestureStartVolume = 1.0;
  double _gestureStartBrightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  // ✅ Double Tap Variables
  String _doubleTapText = "";
  bool _showDoubleTap = false;
  Alignment _doubleTapAlignment = Alignment.centerRight;

  // ✅ UI Controls
  bool _showTitle = true;
  Timer? _titleTimer;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
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

  double _calculateAspectRatio(BuildContext context) {
    if (_aspectRatioMode == "Fill") {
      return MediaQuery.of(context).size.aspectRatio;
    } else if (_aspectRatioMode == "Stretch") {
      return 16 / 9;
    } else {
      return _videoController.value.isInitialized
          ? _videoController.value.aspectRatio
          : 1.0;
    }
  }

  void _recreateChewieController(BuildContext context) {
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: _isLooping,
      aspectRatio: _calculateAspectRatio(context),
      allowFullScreen: false,
      allowMuting: true,
      showControls: false,
      showOptions: false,
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
      _chewieController = null;

      final fileToPlay = _playlist[_currentIndex];
      _videoController = VideoPlayerController.file(fileToPlay);
      await _videoController.initialize();
      _videoController.addListener(_videoListener);

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

  void _handleDoubleTapDown(TapDownDetails details, Size screenSize) {
    final isLeft = details.localPosition.dx < screenSize.width / 2;
    final currentPos = _videoController.value.position;

    setState(() {
      if (isLeft) {
        _videoController.seekTo(currentPos - const Duration(seconds: 10));
        _doubleTapText = "⏪ 10s";
        _doubleTapAlignment = Alignment.centerLeft;
      } else {
        _videoController.seekTo(currentPos + const Duration(seconds: 10));
        _doubleTapText = "10s ⏩";
        _doubleTapAlignment = Alignment.centerRight;
      }
      _showDoubleTap = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showDoubleTap = false);
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

  // ✅ Three-Dots Options Sheet
  void _showVideoOptionsSheet() {
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // 1. Playback Speed
            ListTile(
              leading: const Icon(Icons.speed, color: Colors.white),
              title: const Text('Playback Speed', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSpeedSheet();
              },
            ),

            // 2. Loop Video
            ListTile(
              leading: Icon(
                _isLooping ? Icons.repeat_one : Icons.repeat,
                color: _isLooping ? const Color(0xFF34D399) : Colors.white,
              ),
              title: const Text('Loop Video', style: TextStyle(color: Colors.white)),
              trailing: Text(
                _isLooping ? 'ON' : 'OFF',
                style: TextStyle(
                  color: _isLooping ? const Color(0xFF34D399) : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleLoop();
              },
            ),

            // 3. Brightness Control
            ListTile(
              leading: const Icon(Icons.brightness_6, color: Colors.white),
              title: const Text('Brightness', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '${(_brightness * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBrightnessSheet();
              },
            ),

            // 4. Volume Boost
            ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.white),
              title: const Text('Volume', style: TextStyle(color: Colors.white)),
              trailing: Text(
                '${(_volume * 100).toInt()}%',
                style: TextStyle(
                  color: _volume > 1.0 ? Colors.orangeAccent : Colors.white70,
                  fontWeight: _volume > 1.0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showVolumeSheet();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
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
                  _aspectRatioMode = "Original";
                  _recreateChewieController(context);
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
                  _aspectRatioMode = "Fill";
                  _recreateChewieController(context);
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
                  _aspectRatioMode = "Stretch";
                  _recreateChewieController(context);
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
      _recreateChewieController(context);
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
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

    if (_videoController.value.isInitialized) {
      double desiredRatio = _calculateAspectRatio(context);

      if (_chewieController == null) {
        _recreateChewieController(context);
      } else if ((_chewieController!.aspectRatio! - desiredRatio).abs() > 0.01) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _recreateChewieController(context);
            });
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) => _startTitleTimer(),
        behavior: HitTestBehavior.translucent,
        child: GestureDetector(
          onDoubleTapDown: (details) => _handleDoubleTapDown(details, screenSize),
          onDoubleTap: () {},
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

              if (_showDoubleTap)
                Align(
                  alignment: _doubleTapAlignment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _doubleTapText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

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
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: _toggleFullscreen,
                          ),
                          // ✅ Three-dots Option Menu Icon
                          IconButton(
                            iconSize: 24,
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: _showVideoOptionsSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Center(
                child: AnimatedOpacity(
                  opacity: _showTitle && !_showDoubleTap ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showTitle || _showDoubleTap,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 55,
                        icon: ValueListenableBuilder(
                          valueListenable: _videoController,
                          builder: (context, VideoPlayerValue value, child) {
                            return Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            );
                          },
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController.value.isPlaying) {
                              _videoController.pause();
                            } else {
                              _videoController.play();
                            }
                          });
                          _startTitleTimer();
                        },
                      ),
                    ),
                  ),
                ),
              ),

              if (_playlist.length > 1 && !_showDoubleTap)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _showTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showTitle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
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
                          Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
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

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showTitle,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 25, top: 20, left: 15, right: 15),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: _videoController,
                            builder: (context, VideoPlayerValue value, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(value.position),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _formatDuration(value.duration),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                      const SizedBox(width: 15),
                                      GestureDetector(
                                        onTap: _showAspectRatioSheet,
                                        child: const Icon(Icons.aspect_ratio, color: Colors.white, size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 12,
                            child: VideoProgressIndicator(
                              _videoController,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Color(0xFF34D399),
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

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
