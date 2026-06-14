import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/app_dependencies.dart';
import 'features/auth/application/session_controller.dart';
import 'features/notificaciones/application/local_notificaciones_service.dart';
import 'features/notificaciones/application/notificaciones_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deps = await AppDependencies.create();

  final session = SessionController(authRepository: deps.authRepository);
  deps.setUnauthorizedHandler(session.onTokenRejected);

  // Notificaciones locales (aviso del sistema con sonido en primer plano).
  final localNotifs = LocalNotificacionesService();
  await localNotifs.init();
  await localNotifs.solicitarPermiso();
  final notificaciones = NotificacionesController(
    repo: deps.notificacionesRepository,
    local: localNotifs,
  );

  runApp(AppUnivalle(
    dependencies: deps,
    session: session,
    notificaciones: notificaciones,
  ));
}
