import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    PermissionStatus status = await Permission.audio.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.audio.request();
      }
    }

    setState(() {
      _permissionGranted = status.isGranted;
    });
  }

  // ✅ Ye function ab class ke ANDAR hai (sirf ek baar)
  Future<List<File>> _getAudioFilesSafely(Directory dir) async {
    try {
      List<File> audioFiles = [];
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File) {
          String extension = entity.path.split(".").last.toLowerCase();
          if (["mp3", "wav", "aac", "flac", "m4a", "ogg"].contains(extension)) {
            audioFiles.add(entity);
          }
        } else if (entity is Directory) {
          audioFiles.addAll(await _getAudioFilesSafely(entity));
        }
      }
      return audioFiles;
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BHAI BHAI APP'),
      ),
      body: Center(
        child: _permissionGranted
            ? const Text(
                'Music Player Ready! Scanning Songs...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            : ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Grant Storage Permission'),
              ),
      ),
    );
  }
}
