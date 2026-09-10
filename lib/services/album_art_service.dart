import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';

class AlbumArtService {
  static final Map<String, String?> _cache = {};
  static String? _cacheDir;

  // ✅ Initialize cache directory
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final albumArtDir = Directory('${dir.path}/album_art');
    if (!await albumArtDir.exists()) {
      await albumArtDir.create(recursive: true);
    }
    _cacheDir = albumArtDir.path;
  }

  // ✅ Get album art path (cached)
  static Future<String?> getAlbumArt(String audioFilePath) async {
    // Cache check
    if (_cache.containsKey(audioFilePath)) {
      final cached = _cache[audioFilePath];
      if (cached == null) return null;
      if (File(cached).existsSync()) return cached;
    }

    try {
      // ✅ Read tags
      final tag = await AudioTags.read(audioFilePath);
      if (tag == null || tag.pictures.isEmpty) {
        _cache[audioFilePath] = null;
        return null;
      }

      // ✅ Save first picture
      final picture = tag.pictures.first;
      final bytes = picture.bytes;
      if (bytes == null || bytes.isEmpty) {
        _cache[audioFilePath] = null;
        return null;
      }

      // ✅ Save to cache folder
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

  // ✅ Clear cache
  static void clearCache() {
    _cache.clear();
  }
}
