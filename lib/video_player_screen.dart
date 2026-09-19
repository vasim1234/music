import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:screen_brightness/screen_brightness.dart';

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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initBrightness();
  }

  Future<void> _initBrightness() async {
    try {
      _brightness = await ScreenBrightness().application;
      setState(() {});
    } catch (e) {
      debugPrint('Brightness init error: $e');
    }
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
        allowFullScreen: true,
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
      await _videoController.setVolume(value);
      setState(() => _volume = value);
    } catch (e) {
      debugPrint('Volume set error: $e');
    }
  }

  // ✅ Brightness Bottom Sheet
  void _showBrightnessSheet() {
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
    _videoController.dispose();
    _chewieController?.dispose();
    // ✅ Brightness reset karo
    ScreenBrightness().resetApplicationScreenBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
        ],
      ),
      body: Center(
        child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Color(0xFF34D399)),
      ),
    );
  }
}
