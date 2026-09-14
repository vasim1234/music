import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'album_art_service.dart';
import 'enhance_sound_screen.dart';
import 'services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

// ✅ 4 PREMIUM THEMES
class AppColors {
  static const Color bg0 = Color(0xFF0B1310);
  static const Color card0 = Color(0xFF13221C);
  static const Color accent0 = Color(0xFF34D399);
  static const List<Color> gradient0 = [
    Color(0xFF059669),
    Color(0xFF34D399),
  ];

  static const Color bg1 = Color(0xFF121212);
  static const Color card1 = Color(0xFF1E1E1E);
  static const Color accent1 = Color(0xFFD4AF37);
  static const List<Color> gradient1 = [
    Color(0xFFD4AF37),
    Color(0xFFC5A059),
  ];

  static const Color bg2 = Color(0xFF0A0E1A);
  static const Color card2 = Color(0xFF141B2D);
  static const Color accent2 = Color(0xFF06B6D4);
  static const List<Color> gradient2 = [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
  ];

  static const Color bg3 = Color(0xFF0F0F14);
  static const Color card3 = Color(0xFF181820);
  static const Color accent3 = Color(0xFF8B5CF6);
  static const List<Color> gradient3 = [
    Color(0xFF8B5CF6),
    Color(0xFFD946EF),
  ];
}

class AppTheme {
  static int themeIndex = 0;

  static Color get bg {
    switch (themeIndex) {
      case 0: return AppColors.bg0;
      case 1: return AppColors.bg1;
      case 2: return AppColors.bg2;
      case 3: return AppColors.bg3;
      default: return AppColors.bg0;
    }
  }

  static Color get card {
    switch (themeIndex) {
      case 0: return AppColors.card0;
      case 1: return AppColors.card1;
      case 2: return AppColors.card2;
      case 3: return AppColors.card3;
      default: return AppColors.card0;
    }
  }

  static Color get accent {
    switch (themeIndex) {
      case 0: return AppColors.accent0;
      case 1: return AppColors.accent1;
      case 2: return AppColors.accent2;
      case 3: return AppColors.accent3;
      default: return AppColors.accent0;
    }
  }

  static List<Color> get primaryGradient {
    switch (themeIndex) {
      case 0: return AppColors.gradient0;
      case 1: return AppColors.gradient1;
      case 2: return AppColors.gradient2;
      case 3: return AppColors.gradient3;
      default: return AppColors.gradient0;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initAudioService();
    debugPrint('✅ AudioService initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ AudioService init error: $e');
    debugPrint('Stack: $stackTrace');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhai Bhai Music',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.bg,
      ),
      home: const MusicPlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ... (Baaki MusicPlayerScreen wala code jo humne pichle message mein diya tha)
