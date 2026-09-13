import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static int _notificationId = 1;

  static VoidCallback? _onPlayPause;
  static VoidCallback? _onNext;
  static VoidCallback? _onPrevious;
  static VoidCallback? _onClose;

  static void setCallbacks({
    VoidCallback? onPlayPause,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onClose,
  }) {
    _onPlayPause = onPlayPause;
    _onNext = onNext;
    _onPrevious = onPrevious;
    _onClose = onClose;
  }

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // ✅ Create Notification Channel with Media Style
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'music_player_channel',
        'Music Player',
        description: 'Now playing music controls',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    switch (response.actionId) {
      case 'play_pause':
        _onPlayPause?.call();
        break;
      case 'next':
        _onNext?.call();
        break;
      case 'previous':
        _onPrevious?.call();
        break;
      case 'close':
        _onClose?.call();
        break;
    }
  }

  // ✅ MEDIA STYLE NOTIFICATION
  static Future<void> showNowPlayingNotification({
    required String title,
    required String artist,
    required bool isPlaying,
    String? albumArtPath,
    Color? accentColor,
  }) async {
    // Album art as large icon
    AndroidBitmap<Object>? largeIcon;
    if (albumArtPath != null && File(albumArtPath).existsSync()) {
      largeIcon = FilePathAndroidBitmap(albumArtPath);
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'music_player_channel',
      'Music Player',
      channelDescription: 'Now playing music controls',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      largeIcon: largeIcon,
      color: accentColor ?? const Color(0xFF8B5CF6),
      colorized: false, // ✅ Keep album art colors
      playSound: false,
      enableVibration: false,
      showWhen: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.transport,
      visibility: NotificationVisibility.public,
      // ✅ MEDIA STYLE - yeh asli magic hai
      styleInformation: const MediaStyleInformation(
        showActionsInCompactView: true,
      ),
      // ✅ Compact Media Actions (Bade iconcolor
      actions: <AndroidNotificationAction>[
  const AndroidNotificationAction(
    'previous',
    'Previous',
    icon: DrawableResourceAndroidBitmap('ic_skip_previous'), // ✅ Ye file ab exist karti hai
    showsUserInterface: false,
    cancelNotification: false,
  ),
  AndroidNotificationAction(
    'play_pause',
    isPlaying ? 'Pause' : 'Play',
    icon: DrawableResourceAndroidBitmap(
      isPlaying ? 'ic_pause' : 'ic_play_arrow',
    ),
    showsUserInterface: false,
    cancelNotification: false,
  ),
  const AndroidNotificationAction(
    'next',
    'Next',
    icon: DrawableResourceAndroidBitmap('ic_skip_next'), // ✅ Ye file ab exist karti hai
    showsUserInterface: false,
    cancelNotification: false,
  ),
],

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      _notificationId,
      title,
      artist,
      details,
      payload: 'now_playing',
    );
  }

  static Future<void> cancelNotification() async {
    await _notifications.cancelAll();
  }
}
