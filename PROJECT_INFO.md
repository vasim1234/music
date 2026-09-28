# Bhai Bhai Music - Project Info

## 📱 App Overview
- **Name:** Bhai Bhai Music
- **Type:** Local Music + Video Player
- **Package:** com.example.music_player
- **Flutter Version:** 3.29.0
- **Kotlin Version:** 2.0.21
- **compileSdk:** 36

## 🎯 Features

### 🎵 Music Player
1. Local songs play, notification + lock screen controls
2. Folder-wise view — songs folder ke hisaab se
3. Favorites, Recent, Playlists — local storage
4. Clean Song Names — (MP3 320K) hataata hai
5. Animated Playing Indicator — 3 bars

### 🎛️ Audio Enhancements (Advanced)
1. **Bass Boost** — Custom intensity (0-100%)
2. **Immersive Audio** — 3D surround (0-100%)
3. **5-Band Equalizer** — 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
4. **8 Built-in Presets** — Flat, Rock, Pop, Jazz, Classical, BassBoost, TrebleBoost, Vocal
5. **Custom Preset Save** — User apna EQ save kar sakta hai
6. **Live Frequency Curve** — Real-time graph jo slider ghumane pe badalta hai
7. **Reverb Effect** — 7 presets (Off, Small/Medium/Large Room, Medium/Large Hall, Plate) ⚠️ kuch phones pe kaam nahi karta
8. **Loudness Enhancer** — Quiet audio boost (0-15 dB)
9. **3D Audio Quick Toggle** — Drawer + AppBar mein

### 🎬 Video Player
1. Chewie-based video player
2. Pinch-to-zoom
3. Brightness/volume swipe
4. Playback speed control
5. Aspect ratio adjustment
6. Loop + Auto-play next
7. Share functionality

### 🎨 Themes & UI
1. **2 Premium Themes** — Emerald (Green), Indigo (Blue)
2. **Light/Dark Mode** — Toggle from drawer + AppBar
3. **Unified Audio Settings Screen** — Sab audio features ek page pe

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  file_picker: ^8.0.0
  permission_handler: ^11.3.1
  shared_preferences: ^2.2.2
  audiotags: ^1.4.2
  path_provider: ^2.1.4
  audio_service: ^0.18.15
  just_audio: ^0.9.40
  video_player: ^2.8.7
  chewie: ^1.7.4
  package_info_plus: ^8.1.0
  screen_brightness: ^2.1.2
  volume_controller: ^3.3.3
  share_plus: ^10.0.0  # (optional, video share ke liye)
