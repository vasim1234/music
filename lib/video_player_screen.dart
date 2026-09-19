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

  // ✅ Brightness
  double _brightness = 0.5;

  // ✅ Volume
  double _volume = 1.0;

  // ✅ Gesture
  double _gestureStartX = 0;
  double _gestureStartY = 0;
  double _gestureStartVolume = 1.0;
  double _gestureStartBrightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  // ✅ Title auto-hide
  bool _showTitle = true;
  Timer? _titleTimer;

  // ✅ Playback Speed
  double _playbackSpeed = 1.0;

  // ✅ Aspect Ratio
  double _aspectRatio = 1.0;

  // ✅ Loop
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

  // ✅ ChewieController recreate karne ka method
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
      setState(() => _brightness = value);
    } catch (e) {
      debugPrint('Brightness set error: $e');
    }
  }

  Future<void> _setVolume(double value) async {
    try {
      await _videoController.setVolume(value.clamp(0.0, 1.0));
      setState(() => _volume = value.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Volume set error: $e');
    }
  }

  // ✅ Gesture Handling
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
          (details.localPosition.dy - _gestureStartY) / screenSize.height;
      double newVolume = (_gestureStartVolume - delta).clamp(0.0, 1.0);
      _setVolume(newVolume);
      setState(() {
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      });
    } else {
      double delta =
          (details.localPosition.dy - _gestureStartY) / screenSize.height;
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

  // ✅ Brightness Sheet
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
                  const Icon(Icons.brightness_low,
                      color: Colors.white, size: 22),
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
                  const Icon(Icons.brightness_high,
                      color: Colors.white, size: 22),
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

  // ✅ Volume Sheet
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
                'Volume Boost',
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
                      max: 1.0,
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
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Playback Speed Sheet
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
                  color: isSelected
                      ? const Color(0xFF34D399)
                      : Colors.white54,
                ),
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF34D399) : Colors.white,
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

  // ✅ Aspect Ratio Sheet
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

  // ✅ Loop Toggle
  void _toggleLoop() {
    _startTitleTimer();
    setState(() {
      _isLooping = !_isLooping;
      _recreateChewieController();
    });
    _showSnackBar(_isLooping ? '🔁 Loop ON' : '➡️ Loop OFF');
  }

  // ✅ Fullscreen Toggle
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
    setState(() {});
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    _videoController.dispose();
    _chewieController?.dispose();
    ScreenBrightness().resetApplicationScreenBrightness();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_showTitle,
            child: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.videoFile.path.split('/').last,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // ✅ Playback Speed
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.speed, color: Colors.white),
                  tooltip: 'Playback Speed',
                  onPressed: _showSpeedSheet,
                ),
                // ✅ Aspect Ratio
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.aspect_ratio, color: Colors.white),
                  tooltip: 'Aspect Ratio',
                  onPressed: _showAspectRatioSheet,
                ),
                // ✅ Loop
                IconButton(
                  iconSize: 22,
                  icon: Icon(
                    _isLooping ? Icons.repeat_one : Icons.repeat,
                    color: _isLooping ? const Color(0xFF34D399) : Colors.white,
                  ),
                  tooltip: 'Loop',
                  onPressed: _toggleLoop,
                ),
                // ✅ Brightness
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.brightness_6, color: Colors.white),
                  tooltip: 'Brightness',
                  onPressed: _showBrightnessSheet,
                ),
                // ✅ Volume
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  tooltip: 'Volume',
                  onPressed: _showVolumeSheet,
                ),
                // ✅ Fullscreen
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  tooltip: 'Fullscreen',
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          _startTitleTimer();
        },
        onPanStart: (details) => _onGestureStart(details, screenSize),
        onPanUpdate: (details) => _onGestureUpdate(details, screenSize),
        onPanEnd: _onGestureEnd,
        child: Stack(
          children: [
            Center(
              child: _chewieController != null &&
                      _chewieController!
                          .videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator(color: Color(0xFF34D399)),
            ),

            // ✅ Volume Indicator (Left side)
            if (_showVolumeIndicator)
              Positioned(
                left: 40,
                top: screenSize.height / 2 - 40,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.volume_up,
                          color: Colors.white, size: 35),
                      const SizedBox(height: 10),
                      Text(
                        '${(_volume * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ Brightness Indicator (Right side)
            if (_showBrightnessIndicator)
              Positioned(
                right: 40,
                top: screenSize.height / 2 - 40,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.brightness_6,
                          color: Colors.white, size: 35),
                      const SizedBox(height: 10),
                      Text(
                        '${(_brightness * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
