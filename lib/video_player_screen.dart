import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  // ✅ Brightness & Volume
  double _brightness = 0.5;
  double _volume = 1.0; // Max 2.0 (200%)

  // ✅ Pinch-to-Zoom Scale
  double _scaleFactor = 1.0;
  double _baseScaleFactor = 1.0;

  // ✅ Gesture Controls
  double _gestureStartX = 0;
  double _gestureStartY = 0;
  double _gestureStartVolume = 1.0;
  double _gestureStartBrightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  // ✅ UI Controls
  bool _showTitle = true;
  Timer? _titleTimer;
  double _playbackSpeed = 1.0;
  double _aspectRatio = 1.0;
  bool _isLooping = false;

  @override
  void initState() {
    super.initState();
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
      showOptions: false, // Default 3-dots option hide kiya
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
      _videoController = VideoPlayerController.file(widget.videoFile);
      await _videoController.initialize();

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
      // ✅ 0.0 se 2.0 tak support (200% boost)
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

  // ✅ Volume Sheet (Up to 200%)
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
                      max: 2.0, // ✅ 200% Volume
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
                    fontWeight: _volume > 1.0 ? FontWeight.bold : FontWeight.normal),
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              title: const Text('Fit (Original)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _scaleFactor = 1.0;
                  _aspectRatio = _videoController.value.aspectRatio;
                  _recreateChewieController();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_free, color: Colors.white),
              title: const Text('Fill (Cover)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _scaleFactor = 1.0;
                  _aspectRatio = MediaQuery.of(context).size.aspectRatio;
                  _recreateChewieController();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fullscreen, color: Colors.white),
              title: const Text('Stretch (16:9)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _scaleFactor = 1.0;
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
            _baseScaleFactor = _scaleFactor;
          },
          onScaleUpdate: (details) {
            // ✅ Pinch to zoom support
            if (details.scale != 1.0) {
              setState(() {
                _scaleFactor = (_baseScaleFactor * details.scale).clamp(1.0, 3.0);
              });
            }
          },
          onPanStart: (details) => _onGestureStart(details, screenSize),
          onPanUpdate: (details) => _onGestureUpdate(details, screenSize),
          onPanEnd: _onGestureEnd,
          child: Stack(
            children: [
              // ✅ 1. Pinch-to-Zoom enabled Video View
              Center(
                child: Transform.scale(
                  scale: _scaleFactor,
                  child: _chewieController != null &&
                          _chewieController!
                              .videoPlayerController.value.isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator(color: Color(0xFF34D399)),
                ),
              ),

              // ✅ 2. Top Transparent Overlay Navigation Bar
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
                        title: Text(
                          widget.videoFile.path.split('/').last,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        actions: [
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.speed, color: Colors.white),
                            onPressed: _showSpeedSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.aspect_ratio, color: Colors.white),
                            onPressed: _showAspectRatioSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: Icon(
                              _isLooping ? Icons.repeat_one : Icons.repeat,
                              color: _isLooping ? const Color(0xFF34D399) : Colors.white,
                            ),
                            onPressed: _toggleLoop,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.brightness_6, color: Colors.white),
                            onPressed: _showBrightnessSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.volume_up, color: Colors.white),
                            onPressed: _showVolumeSheet,
                          ),
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: _toggleFullscreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ 3. Patla aur Lamba Volume Overlay (MX-Player style)
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
                          color: _volume > 1.0 ? Colors.orangeAccent : Colors.white,
                          size: 20,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: LinearProgressIndicator(
                                value: _volume / 2.0, // 200% scale
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
                            color: _volume > 1.0 ? Colors.orangeAccent : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ✅ 4. Patla aur Lamba Brightness Overlay (MX-Player style)
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
                        const Icon(Icons.brightness_6, color: Colors.white, size: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: LinearProgressIndicator(
                                value: _brightness,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
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
            ],
          ),
        ),
      ),
    );
  }
}
