import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static int _notificationId = 1;

  // ✅ Callbacks
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

  static VoidCallback? get onPlayPause => _onPlayPause;
  static set onPlayPause(VoidCallback? callback) => _onPlayPause = callback;

  static VoidCallback? get onNext => _onNext;
  static set onNext(VoidCallback? callback) => _onNext = callback;

  static VoidCallback? get onPrevious => _onPrevious;
  static set onPrevious(VoidCallback? callback) => _onPrevious = callback;

  static VoidCallback? get onClose => _onClose;
  static set onClose(VoidCallback? callback) => _onClose = callback;

  // ✅ Initialize
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  // ✅ Handle notification button clicks
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

  // ✅ Show Now Playing Notification
  static Future<void> showNowPlayingNotification({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    // ✅ const hata kar final kar diya gaya hai
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
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'previous',
          '⏮️ Prev',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'play_pause',
          isPlaying ? '⏸️ Pause' : '▶️ Play',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'next',
          '⏭️ Next',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'close',
          '⏹️ Close',
          showsUserInterface: true,
        ),
      ],
    );

    // ✅ yahan se bhi const hata kar final kar diya gaya hai
    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      _notificationId,
      isPlaying ? '▶️ Now Playing: $title' : '⏸️ Paused: $title',
      artist,
      details,
      payload: 'now_playing',
    );
  }

  // ✅ Update Play/Pause button
  static Future<void> updatePlayPauseButton(
    bool isPlaying,
    String title,
    String artist,
  ) async {
    await showNowPlayingNotification(
      title: title,
      artist: artist,
      isPlaying: isPlaying,
    );
  }

  // ✅ Cancel Notification
  static Future<void> cancelNotification() async {
    await _notifications.cancelAll();
  }
}
