/// Raiz de la aplicacion.
///
/// Provee dependencias, sesion y notificaciones al arbol; crea el router una
/// vez; dispara el auto-login; y controla el ciclo de vida del polling de
/// notificaciones (arranca al autenticarse, para al cerrar sesion, pausa/reanuda
/// con el lifecycle de la app).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/di/app_dependencies.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/session_controller.dart';
import '../features/notificaciones/application/notificaciones_controller.dart';
import 'router.dart';

class AppUnivalle extends StatefulWidget {
  const AppUnivalle({
    super.key,
    required this.dependencies,
    required this.session,
    required this.notificaciones,
  });

  final AppDependencies dependencies;
  final SessionController session;
  final NotificacionesController notificaciones;

  @override
  State<AppUnivalle> createState() => _AppUnivalleState();
}

class _AppUnivalleState extends State<AppUnivalle> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = crearRouter(widget.session);
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_onSessionChanged);
    widget.session.cargarSesion();
  }

  void _onSessionChanged() {
    if (widget.session.status == SessionStatus.autenticado) {
      widget.notificaciones.iniciar();
    } else {
      widget.notificaciones.detener();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.notificaciones.reanudar();
    } else if (state == AppLifecycleState.paused) {
      widget.notificaciones.pausar();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: widget.dependencies),
        ChangeNotifierProvider<SessionController>.value(value: widget.session),
        ChangeNotifierProvider<NotificacionesController>.value(
          value: widget.notificaciones,
        ),
      ],
      child: MaterialApp.router(
        title: 'AppUnivalle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
