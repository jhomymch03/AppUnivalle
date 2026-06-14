/// Controlador de sesion (estado compartido via Provider).
///
/// Es la unica fuente de verdad del estado de autenticacion de la app. La
/// navegacion (go_router) lo observa para decidir que pantalla mostrar:
///   - [SessionStatus.desconocido]   -> Splash (resolviendo auto-login).
///   - [SessionStatus.autenticando]  -> el login muestra su spinner.
///   - [SessionStatus.autenticado]   -> Home del estudiante.
///   - [SessionStatus.noAutenticado] -> Login.
///   - [SessionStatus.accesoDenegado]-> pantalla "solo estudiantes".
///
/// Regla de negocio clave (esta app es SOLO para estudiantes): si el login es
/// correcto pero el rol no es `estudiante`, se cierra la sesion y se pasa a
/// [SessionStatus.accesoDenegado].
library;

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/login_request.dart';
import '../data/models/rol_usuario.dart';
import '../data/models/usuario_me.dart';

enum SessionStatus {
  desconocido,
  autenticando,
  autenticado,
  noAutenticado,
  accesoDenegado,
}

class SessionController extends ChangeNotifier {
  SessionController({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  SessionStatus _status = SessionStatus.desconocido;
  UsuarioMe? _usuario;
  String? _errorMessage;

  SessionStatus get status => _status;
  UsuarioMe? get usuario => _usuario;

  /// Mensaje de error del ultimo intento de login (para mostrar en la UI).
  String? get errorMessage => _errorMessage;

  /// Resuelve el estado inicial al arrancar la app (auto-login).
  ///
  /// Si hay token guardado, consulta `/me`: con rol estudiante -> autenticado;
  /// otro rol -> accesoDenegado; 401 (token vencido) -> noAutenticado.
  Future<void> cargarSesion() async {
    if (!await _authRepository.haySesion()) {
      _set(SessionStatus.noAutenticado);
      return;
    }
    try {
      final usuario = await _authRepository.obtenerPerfil();
      await _aplicarUsuario(usuario);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _authRepository.logout();
      } else {
        // Error de red al verificar: pedimos login, sin borrar el token.
        _errorMessage = e.message;
      }
      _set(SessionStatus.noAutenticado);
    }
  }

  /// Inicia sesion con email + password y aplica el guard de rol.
  Future<void> login(String email, String password) async {
    _errorMessage = null;
    _set(SessionStatus.autenticando);
    try {
      await _authRepository.login(
        LoginRequest(email: email.trim(), password: password),
      );
      final usuario = await _authRepository.obtenerPerfil();
      await _aplicarUsuario(usuario);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _set(SessionStatus.noAutenticado);
    }
  }

  /// Cierra sesion (logout manual del estudiante).
  Future<void> logout() async {
    await _authRepository.logout();
    _usuario = null;
    _errorMessage = null;
    _set(SessionStatus.noAutenticado);
  }

  /// Vuelve al login desde la pantalla de acceso denegado.
  void volverALogin() {
    _errorMessage = null;
    _set(SessionStatus.noAutenticado);
  }

  /// Refresca en memoria el usuario tras editar el perfil (PATCH /auth/me).
  /// No cambia el [SessionStatus]; solo actualiza los datos visibles.
  void actualizarUsuarioLocal(UsuarioMe usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  /// Lo invoca el interceptor cuando un request autenticado recibe 401
  /// (token vencido/rechazado). El token ya fue borrado por el interceptor.
  void onTokenRejected() {
    _usuario = null;
    _set(SessionStatus.noAutenticado);
  }

  /// Aplica el guard de rol: solo `estudiante` entra; el resto queda bloqueado.
  Future<void> _aplicarUsuario(UsuarioMe usuario) async {
    if (usuario.rol == RolUsuario.estudiante) {
      _usuario = usuario;
      _set(SessionStatus.autenticado);
    } else {
      _usuario = null;
      await _authRepository.logout();
      _set(SessionStatus.accesoDenegado);
    }
  }

  void _set(SessionStatus status) {
    _status = status;
    notifyListeners();
  }
}
