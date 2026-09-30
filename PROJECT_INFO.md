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
6. Shuffle, Repeat All, Repeat One — working
7. Auto-play next song on completion
8. **Dynamic Album Art Theme** — Background gradient album art colors se
9. **Always Dark Full Screen Player** — Premium look har mode mein
10. **Smart Empty State** — Scan Music button with auto-discovery

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
10. **State Persistence** — EQ settings, Bass, Reverb, Loudness — app restart pe bhi save rehte hain
11. **Theme Accent Buttons** — Play/Pause, sliders, shuffle/repeat — hamesha theme color use karte hain

### 🎬 Video Player
1. Chewie-based video player
2. Pinch-to-zoom
3. Brightness/volume swipe (left = volume, right = brightness)
4. Double-tap seek (10s forward/backward)
5. Playback speed control (0.5x to 2x)
6. Aspect ratio adjustment (Fit / Fill / Stretch)
7. Loop + Auto-play next
8. Rotate screen button (Portrait/Landscape)
9. **Playback buttons below progress bar** (YouTube style)
10. **Audio Settings shortcut** in video player
11. Share Video
12. Delete Video
13. **Video list options** — 3-dot menu + long-press (Play, Share, Delete)

### 🎨 Themes & UI
1. **2 Premium Themes** — Emerald (Green), Indigo (Blue)
2. **Light/Dark Mode** — Toggle from drawer + AppBar
3. **Unified Audio Settings Screen** — Sab audio features ek page pe
4. **Dynamic Album Art Theme** — Album art se colors extract hote hain, background gradient mein use hote hain
5. **Theme Accent Buttons** — Play/Pause, sliders, shuffle/repeat — hamesha theme color use karte hain
6. **Always Dark Full Screen Player** — Full screen player hamesha dark rehta hai
7. **Emoji-Free Clean Design** — Sab emojis hata diye, professional look
8. **Status Bar Fix** — Top bar status bar ke saath overlap nahi hota
9. **Premium Empty State** — Scan Music button with gradient + glow

### 📢 Distribution & Sharing
1. **Share App** — Drawer se app share karo (WhatsApp, Telegram, SMS, Gmail)
2. **Telegram Channel** — [t.me/bhaibhaimusic](https://t.me/bhaibhaimusic) — APK direct download
3. **Indus Appstore** — Verification pending
4. **Permanent Keystore** — GitHub Actions se signed APK builds

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
  share_plus: ^10.0.0
  palette_generator: ^0.3.3+6
  url_launcher: ^6.3.0

lib/
├── main.dart                       # Music player + UI + themes + drawer
├── video_player_screen.dart        # Video player with all features
├── album_art_service.dart          # Album art widget + palette provider
├── audio_settings_screen.dart      # ⭐ UNIFIED audio settings (Bass, EQ, Reverb, Loudness)
├── enhance_sound_screen.dart       # (Deprecated — merged into audio_settings)
├── equalizer_screen.dart           # (Deprecated — merged into audio_settings)
└── services/
    └── audio_handler.dart          # audio_service setup + MethodChannel

android/app/src/main/kotlin/com/example/music_player/
├── MainActivity.kt                 # AudioServiceActivity + MethodChannel register
└── BassBoostPlugin.kt              # Native audio effects (BassBoost, Virtualizer, Equalizer, Reverb, LoudnessEnhancer)

.github/workflows/
└── build.yml                       # GitHub Actions — signed APK builds



## 🔐 Keystore & Signing

### Keystore Details
- **File:** `bhaibhai-key.jks`
- **Password:** `BhaiBhai2026`
- **Alias:** `bhaibhai`
- **Key Password:** `BhaiBhai2026`
- **Validity:** 10,000 days (~27 years)

### GitHub Secrets (4)
| Secret Name | Value |
|-------------|-------|
| `KEYSTORE_BASE64` | Keystore file Base64 |
| `KEYSTORE_PASSWORD` | BhaiBhai2026 |
| `KEY_ALIAS` | bhaibhai |
| `KEY_PASSWORD` | BhaiBhai2026 |

### Signing Setup
- **`android/app/build.gradle.kts`** — signingConfigs with env vars
- **`.github/workflows/build.yml`** — Decode keystore step + build with env
- **Keystore backup** — 3 jagah (phone, Google Drive, email)

## 🐛 Known Issues Fixed

- ✅ Gradle 8.7 + AGP 8.3.0 + Kotlin 2.0.21
- ✅ AudioServiceActivity for notification
- ✅ Folder-wise songs sahi bajte hain
- ✅ Video player fullscreen black bars fix
- ✅ AppBar icons auto-hide + tap to show
- ✅ Duplicate fullscreen button hataya
- ✅ 12 Indian languages auto-translate
- ✅ `setStrength()` Short type fix
- ✅ Equalizer + Live Frequency Curve working
- ✅ Reverb + LoudnessEnhancer API integrated
- ✅ Unified Audio Settings screen
- ✅ Theme reduction to 2 (Emerald, Indigo)
- ✅ Dynamic Album Art Theme (palette_generator)
- ✅ Always Dark Full Screen Player
- ✅ Status Bar Overlap Fix
- ✅ Emoji Removal (clean look)
- ✅ Video Delete/Share in list
- ✅ Video Player Buttons Redesign (YouTube style)
- ✅ Theme Accent for Buttons
- ✅ Audio Settings — Theme Based
- ✅ Scaffold Background Fix
- ✅ Equalizer State Persistence Fix
- ✅ Share App Feature
- ✅ Telegram Channel + Deep Link
- ✅ Scan Music Empty State Button
- ✅ Permanent Keystore Setup

## 🚧 TODO / Future Features

### High Priority
- [ ] **Sleep Timer** — N minutes baad auto-stop
- [ ] **Playback Speed (Music)** — 0.5x to 2x
- [ ] **Lyrics Support** — .lrc files

### Medium Priority
- [ ] **Audio Visualizer** — Live waveform/bars
- [ ] **Widget** — Home screen mini player
- [ ] **App Lock** — PIN/biometric

### Future
- [ ] **Play Store Publish**
- [ ] **App Icon + Splash Screen** redesign
- [ ] **Tabs Layout Fix** — 6 tabs screen pe fit nahi

## 📝 Notes

- Music + Video dono ek app mein
- Local files only (no download)
- No copyrighted content hosted
- Permanent keystore — app updates same signature
- Telegram channel — direct APK distribution
- Made with love by Bhai Bhai
