/// Repositorio de autenticacion.
///
/// Unico punto de acceso a los endpoints `/api/v1/auth/*` del backend.
/// Encapsula las llamadas Dio, persiste el token tras el login y traduce
/// cualquier `DioException` a [ApiException] tipada. La capa de UI solo habla
/// con esta clase; nunca ve Dio ni JSON crudo.
///
/// Endpoints reales usados (no se inventa ninguno):
///   - POST   /auth/login            -> [login]
///   - GET    /auth/me               -> [obtenerPerfil]
///   - POST   /auth/cambiar-password -> [cambiarPassword]
///   - (logout es local: borra el token)
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import 'models/login_request.dart';
import 'models/token_response.dart';
import 'models/usuario_me.dart';

class AuthRepository {
  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Inicia sesion con email + password.
  ///
  /// Persiste el access token en almacenamiento seguro y devuelve el
  /// [TokenResponse]. Lanza [ApiException] (401 si las credenciales fallan).
  Future<TokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );
      final token = TokenResponse.fromJson(response.data!);
      await _tokenStorage.saveToken(token.accessToken);
      return token;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Devuelve el perfil del usuario autenticado (`GET /auth/me`).
  ///
  /// El token se inyecta automaticamente via interceptor. Lanza
  /// [ApiException] (401 si no hay sesion valida).
  Future<UsuarioMe> obtenerPerfil() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return UsuarioMe.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Actualiza nombres/apellidos/telefono del propio usuario (`PATCH /auth/me`).
  /// Devuelve el perfil actualizado. Envia los tres campos (como el web).
  Future<UsuarioMe> actualizarPerfil({
    required String nombres,
    required String apellidos,
    String? telefono,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/me',
        data: {
          'nombres': nombres,
          'apellidos': apellidos,
          'telefono': telefono,
        },
      );
      return UsuarioMe.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cambia la contraseña del usuario autenticado (`POST /auth/cambiar-password`).
  ///
  /// El backend valida la contraseña actual y responde 204. Lanza
  /// [ApiException] (400 si la contraseña actual es incorrecta).
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      await _dio.post<void>(
        '/auth/cambiar-password',
        data: {
          'password_actual': passwordActual,
          'password_nueva': passwordNueva,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cierra sesion localmente borrando el token.
  ///
  /// El backend usa JWT sin estado: no hay endpoint de logout, basta con
  /// descartar el token del dispositivo.
  Future<void> logout() => _tokenStorage.clear();

  /// `true` si hay un token persistido (para decidir la pantalla inicial).
  Future<bool> haySesion() => _tokenStorage.hasToken();
}
