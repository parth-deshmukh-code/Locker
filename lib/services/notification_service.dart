import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  Future<void> init() async {
    await _notif.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    ));

    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'locker_alert',
      'Locker Alerts',
      description: 'Alert when locker is opened',
      importance: Importance.max,
      enableVibration: true,
    ));
  }

  Future<void> showAlert(String deviceName) async {
    await _notif.show(
      deviceName.hashCode,
      '🔴 $deviceName — ALERT!',
      'Movement detected! Check immediately.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'locker_alert', 'Locker Alerts',
          importance: Importance.max, priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }

  Future<void> playAlarm() async {
    if (_playing) return;
    _playing = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/alarm.mp3'));
  }

  Future<void> stopAlarm() async {
    if (!_playing) return;
    _playing = false;
    await _player.stop();
  }

  bool get isPlaying => _playing;
}
