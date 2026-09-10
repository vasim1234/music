import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';

class AlbumArtService {
  static final Map<String, String?> _cache = {};
  static final Map<String, Future<String?>> _futureCache = {};
  static String? _cacheDir;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final albumArtDir = Directory('${dir.path}/album_art');
    if (!await albumArtDir.exists()) {
      await albumArtDir.create(recursive: true);
    }
    _cacheDir = albumArtDir.path;
  }

  static Future<String?> getAlbumArt(String audioFilePath) {
    if (_futureCache.containsKey(audioFilePath)) {
      return _futureCache[audioFilePath]!;
    }
    final future = _loadAlbumArt(audioFilePath);
    _futureCache[audioFilePath] = future;
    return future;
  }

  static Future<String?> _loadAlbumArt(String audioFilePath) async {
    if (_cache.containsKey(audioFilePath)) {
      final cached = _cache[audioFilePath];
      if (cached == null) return null;
      if (File(cached).existsSync()) return cached;
    }

    try {
      final tag = await AudioTags.read(audioFilePath);
      if (tag == null || tag.pictures.isEmpty) {
        _cache[audioFilePath] = null;
        return null;
      }

      final picture = tag.pictures.first;
      final bytes = picture.bytes;
      if (bytes == null || bytes.isEmpty) {
        _cache[audioFilePath] = null;
        return null;
      }

      final fileName = '${audioFilePath.hashCode}.jpg';
      final filePath = '$_cacheDir/$fileName';
      final file = File(filePath);

      if (!await file.exists()) {
        await file.writeAsBytes(bytes);
      }

      _cache[audioFilePath] = filePath;
      return filePath;
    } catch (e) {
      print('⚠️ Album art error: $e');
      _cache[audioFilePath] = null;
      return null;
    }
  }

  static void clearCache() {
    _cache.clear();
    _futureCache.clear();
  }
}

// ✅ SEPARATE STATEFULWIDGET - No Flickering
class AlbumArtWidget extends StatefulWidget {
  final String audioPath;
  final double size;
  final bool isPlaying;
  final double borderRadius;
  final bool isCircle;

  const AlbumArtWidget({
    super.key,
    required this.audioPath,
    required this.size,
    this.isPlaying = false,
    this.borderRadius = 0.25,
    this.isCircle = false,
  });

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Sirf tab reload jab path change ho
    if (oldWidget.audioPath != widget.audioPath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });
    final path = await AlbumArtService.getAlbumArt(widget.audioPath);
    if (mounted) {
      setState(() {
        _imagePath = path;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isCircle
        ? widget.size / 2
        : widget.size * widget.borderRadius;

    if (_isLoading || _imagePath == null) {
      return _buildPlaceholder(radius);
    }

    return Container(
      height: widget.size,
      width: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(_imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(radius),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double radius) {
    return Container(
      height: widget.size,
      width: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.6),
            const Color(0xFFD946EF).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        widget.isPlaying ? Icons.graphic_eq : Icons.music_note,
        color: Colors.white,
        size: widget.size * 0.5,
      ),
    );
  }
}
