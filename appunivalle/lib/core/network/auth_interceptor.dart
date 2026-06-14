/// Interceptor de autenticacion.
///
/// Dos responsabilidades:
///  1. Inyectar `Authorization: Bearer <token>` en cada request saliente
///     cuando hay sesion (lee el token de [TokenStorage]).
///  2. Detectar respuestas 401 de **requests que llevaban token**: limpia la
///     sesion y notifica al handler registrado para que la app redirija a
///     login. Un 401 en un request SIN token (p. ej. el propio /auth/login con
///     credenciales malas) NO dispara el handler — es solo un error normal.
///     El backend solo emite access tokens (no hay refresh), asi que un 401
///     autenticado significa "vuelve a iniciar sesion".
library;

import 'package:dio/dio.dart';

import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  /// Se invoca cuando un request autenticado recibe 401. Reasignable para
  /// poder conectarlo al estado de sesion despues de construir el cliente.
  void Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final llevabaToken =
        err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && llevabaToken) {
      // El token guardado fue rechazado: borrar sesion y avisar a la app.
      await _tokenStorage.clear();
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
