/// Configuracion de navegacion (go_router) con redireccion por sesion.
///
/// El `redirect` observa el [SessionController] (via `refreshListenable`) y
/// controla el acceso: ninguna pantalla decide por su cuenta si el usuario
/// puede verla. Un usuario autenticado puede navegar libremente entre las
/// rutas protegidas; solo se le saca de las rutas publicas (login/splash).
library;

import 'package:go_router/go_router.dart';

import '../features/auth/application/session_controller.dart';
import '../features/auth/presentation/acceso_denegado_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/estudiante/presentation/home_estudiante_screen.dart';
import '../features/postulaciones/presentation/mis_postulaciones_screen.dart';
import '../features/postulaciones/presentation/postulacion_detalle_screen.dart';
import '../features/postulaciones/presentation/postulacion_form_screen.dart';
import '../features/postulaciones/presentation/observaciones_screen.dart';
import '../features/postulaciones/presentation/historial_screen.dart';
import '../features/postulaciones/presentation/documentos_screen.dart';
import '../features/postulaciones/presentation/carta_respuesta_screen.dart';
import '../features/notificaciones/presentation/notificaciones_screen.dart';
import '../features/perfil/presentation/perfil_screen.dart';

abstract final class Rutas {
  static const splash = '/splash';
  static const login = '/login';
  static const accesoDenegado = '/acceso-denegado';
  static const home = '/home';
  static const misPostulaciones = '/mis-postulaciones';
  static const nuevaPostulacion = '/postulacion/nueva';
  static const observaciones = '/observaciones';
  static const historial = '/historial';
  static const documentos = '/documentos';
  static const cartaRespuesta = '/carta-respuesta';
  static const perfil = '/perfil';
  static const notificaciones = '/notificaciones';

  /// Rutas no autenticadas (de las que se expulsa a un usuario logueado).
  static const publicas = {splash, login, accesoDenegado};
}

GoRouter crearRouter(SessionController session) {
  return GoRouter(
    initialLocation: Rutas.splash,
    refreshListenable: session,
    routes: [
      GoRoute(path: Rutas.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Rutas.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Rutas.accesoDenegado,
        builder: (_, _) => const AccesoDenegadoScreen(),
      ),
      GoRoute(path: Rutas.home, builder: (_, _) => const HomeEstudianteScreen()),
      GoRoute(
        path: Rutas.misPostulaciones,
        builder: (_, _) => const MisPostulacionesScreen(),
      ),
      GoRoute(
        path: Rutas.nuevaPostulacion,
        builder: (_, _) => const PostulacionFormScreen(),
      ),
      GoRoute(
        path: Rutas.observaciones,
        builder: (_, _) => const ObservacionesScreen(),
      ),
      GoRoute(
        path: Rutas.historial,
        builder: (_, _) => const HistorialScreen(),
      ),
      GoRoute(
        path: Rutas.documentos,
        builder: (_, _) => const DocumentosScreen(),
      ),
      GoRoute(
        path: Rutas.cartaRespuesta,
        builder: (_, _) => const CartaRespuestaScreen(),
      ),
      GoRoute(
        path: Rutas.perfil,
        builder: (_, _) => const PerfilScreen(),
      ),
      GoRoute(
        path: Rutas.notificaciones,
        builder: (_, _) => const NotificacionesScreen(),
      ),
      GoRoute(
        path: '/postulacion/:id',
        builder: (_, state) =>
            PostulacionDetalleScreen(id: state.pathParameters['id']!),
      ),
    ],
    redirect: (_, state) {
      final loc = state.matchedLocation;
      final esPublica = Rutas.publicas.contains(loc);

      switch (session.status) {
        case SessionStatus.desconocido:
          return loc == Rutas.splash ? null : Rutas.splash;
        case SessionStatus.autenticando:
          return null; // el login muestra su propio spinner
        case SessionStatus.noAutenticado:
          return loc == Rutas.login ? null : Rutas.login;
        case SessionStatus.accesoDenegado:
          return loc == Rutas.accesoDenegado ? null : Rutas.accesoDenegado;
        case SessionStatus.autenticado:
          // Logueado: si esta en una ruta publica lo mandamos al home; en
          // cualquier ruta protegida lo dejamos navegar.
          return esPublica ? Rutas.home : null;
      }
    },
  );
}
