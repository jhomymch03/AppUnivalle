// Smoke test del arranque de la app.
//
// Mockea el canal nativo de flutter_secure_storage (sin token) para que el
// auto-login resuelva en "no autenticado" y el router muestre el login.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appunivalle/app/app.dart';
import 'package:appunivalle/core/di/app_dependencies.dart';
import 'package:appunivalle/features/auth/application/session_controller.dart';
import 'package:appunivalle/features/notificaciones/application/local_notificaciones_service.dart';
import 'package:appunivalle/features/notificaciones/application/notificaciones_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock del plugin flutter_secure_storage: read devuelve null (sin sesion).
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('Sin sesion guardada, la app muestra el login',
      (WidgetTester tester) async {
    final deps = await AppDependencies.create();
    final session = SessionController(authRepository: deps.authRepository);
    final localNotifs = LocalNotificacionesService();
    final notificaciones = NotificacionesController(
      repo: deps.notificacionesRepository,
      local: localNotifs,
    );

    await tester.pumpWidget(AppUnivalle(
      dependencies: deps,
      session: session,
      notificaciones: notificaciones,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Correo institucional'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ingresar'), findsOneWidget);
  });
}
