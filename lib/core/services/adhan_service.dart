import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AdhanService {
  static final AdhanService _instance = AdhanService._internal();
  factory AdhanService() => _instance;
  AdhanService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Pas d'implémentation Web ni de plateforme enregistrée en test :
    // les rappels d'adhan sont alors simplement indisponibles.
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {},
      );
    } catch (e) {
      debugPrint('AdhanService: notifications locales indisponibles ($e)');
      return;
    }

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleAdhan({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Use default sound for now, if you add adhan.mp3 to raw/ you can uncomment
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'adhan_channel',
      'Appels à la prière',
      channelDescription: 'Notifications pour les heures de prière (Adhan)',
      importance: Importance.max,
      priority: Priority.high,
      // sound: RawResourceAndroidNotificationSound('adhan'),
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          // sound: 'adhan.wav',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: await scheduleMode(),
    );
  }

  /// Alarme exacte si l'utilisateur l'a autorisée (Android 12+), sinon alarme approximative
  /// (quelques minutes de décalage possibles) plutôt qu'un échec de la planification (SEC-025).
  Future<AndroidScheduleMode> scheduleMode() async {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exact = await android?.canScheduleExactNotifications() ?? true;
    return exactOrInexact(exact);
  }

  @visibleForTesting
  static AndroidScheduleMode exactOrInexact(bool exactAllowed) => exactAllowed
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> cancelAdhan(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
