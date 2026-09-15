import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audiotags/audiotags.dart';

class AlbumArtService {
  static void init() {}

  static Future<File?> getAlbumArt(String audioPath) async {
    try {
      final tag = await AudioTags.read(audioPath);
      final pictures = tag?.pictures;
      if (pictures != null && pictures.isNotEmpty) {
        final picture = pictures.first;
        final bytes = picture.bytes;
        if (bytes != null) {
          final file = File('${Directory.systemTemp.path}/album_art_${audioPath.hashCode}.jpg');
          await file.writeAsBytes(bytes);
          return file;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class AlbumArtWidget extends StatefulWidget {
  final String audioPath;
  final double size;
  final bool isPlaying;
  final bool isCircle;

  const AlbumArtWidget({
    super.key,
    required this.audioPath,
    this.size = 50,
    this.isPlaying = false,
    this.isCircle = false,
  });

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  File? _albumArt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumArt();
  }

  @override
  void didUpdateWidget(AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _loadAlbumArt();
    }
  }

  Future<void> _loadAlbumArt() async {
    setState(() => _loading = true);
    final art = await AlbumArtService.getAlbumArt(widget.audioPath);
    if (mounted) {
      setState(() {
        _albumArt = art;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle ? null : BorderRadius.circular(8),
        color: Colors.grey.shade800,
      ),
      child: ClipRRect(
        borderRadius: widget.isCircle ? BorderRadius.circular(widget.size / 2) : BorderRadius.circular(8),
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _albumArt != null
                ? Image.file(_albumArt!, fit: BoxFit.cover)
                : const Icon(Icons.music_note, color: Colors.white),
      ),
    );
  }
}
