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

  // ✅ Gesture ke liye
  double _gestureStartX = 0;
  double _gestureStartY = 0;
  double _gestureStartVolume = 1.0;
  double _gestureStartBrightness = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  // ✅ Title auto-hide ke liye
  bool _showTitle = true;
  Timer? _titleTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initBrightness();
    _startTitleTimer();

    // ✅ Screen rotation allow karo
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

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.file(widget.videoFile);
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        allowFullScreen: false,   // ✅ Chewie ka fullscreen band (duplicate na ho)
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF34D399),
          handleColor: const Color(0xFF34D399),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightGreen,
        ),
      );

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
    _startTitleTimer();
  }

  void _onGestureUpdate(DragUpdateDetails details, Size screenSize) {
    bool isLeftSide = _gestureStartX < screenSize.width / 2;

    if (isLeftSide) {
      double delta = (details.localPosition.dy - _gestureStartY) / screenSize.height;
      double newVolume = (_gestureStartVolume - delta).clamp(0.0, 1.0);
      _setVolume(newVolume);
      setState(() {
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      });
    } else {
      double delta = (details.localPosition.dy - _gestureStartY) / screenSize.height;
      double newBrightness = (_gestureStartBrightness - delta).clamp(0.0, 1.0);
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

  // ✅ Brightness Bottom Sheet
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

  // ✅ Volume Bottom Sheet
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

  @override
  void dispose() {
    _titleTimer?.cancel();
    _videoController.dispose();
    _chewieController?.dispose();
    ScreenBrightness().resetApplicationScreenBrightness();

    // ✅ Portrait pe wapas
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
      // ✅ AppBar bhi title ke saath hide hoga
      appBar: PreferredSize(
        preferredSize:
            _showTitle ? const Size.fromHeight(kToolbarHeight) : Size.zero,
        child: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
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
              // ✅ Brightness button
              IconButton(
                icon: const Icon(Icons.brightness_6, color: Colors.white),
                tooltip: 'Brightness',
                onPressed: _showBrightnessSheet,
              ),
              // ✅ Volume button
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white),
                tooltip: 'Volume',
                onPressed: _showVolumeSheet,
              ),
              // ✅ Fullscreen button (AppBar wala, kyunki Chewie ka band hai)
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                tooltip: 'Fullscreen',
                onPressed: () async {
                  if (MediaQuery.of(context).orientation ==
                      Orientation.portrait) {
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                    await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersiveSticky);
                  } else {
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                    await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge);
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // ✅ Tap karne pe title wapas dikhega
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
