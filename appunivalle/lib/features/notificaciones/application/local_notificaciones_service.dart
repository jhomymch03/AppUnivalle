// lib/features/notificaciones/application/local_notificaciones_service.dart
/// Envuelve `flutter_local_notifications` para mostrar avisos del sistema con
/// sonido cuando llega una notificacion nueva (solo en primer plano).
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificacionesService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  int _nextId = 0;

  static const _channelId = 'notificaciones_univalle';
  static const _channelNombre = 'Notificaciones';

  /// Inicializa el plugin y crea el canal Android (con sonido por defecto).
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    const canal = AndroidNotificationChannel(
      _channelId,
      _channelNombre,
      description: 'Avisos del trámite de titulación',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  /// Pide el permiso de notificaciones (Android 13+).
  Future<void> solicitarPermiso() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Muestra una notificación del sistema con sonido.
  Future<void> mostrar(String titulo, String cuerpo) async {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelNombre,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(_nextId++, titulo, cuerpo, detalles);
  }
}
