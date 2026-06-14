/// Cliente HTTP central de la app.
///
/// Configura una unica instancia de [Dio] con:
///   - `baseUrl` = `<serverBaseUrl>/api/v1` (ver [ApiConfig.apiBaseUrlFor]).
///   - Timeouts de conexion/recepcion/envio.
///   - Headers JSON por defecto.
///   - Interceptors: autenticacion (Bearer + 401) y logging en debug.
///
/// La URL del servidor es **editable en tiempo de ejecucion** con
/// [updateServerBaseUrl]: cambia `dio.options.baseUrl` sobre la MISMA
/// instancia de Dio, asi los repositorios que ya tienen la referencia siguen
/// funcionando sin reconstruir nada. Esto permite alternar entre LAN y
/// Cloudflare Tunnel desde la pantalla de Configuracion.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required String serverBaseUrl,
  }) : _serverBaseUrl = serverBaseUrl,
       _authInterceptor = AuthInterceptor(tokenStorage: tokenStorage),
       dio = Dio(
         BaseOptions(
           baseUrl: ApiConfig.apiBaseUrlFor(serverBaseUrl),
           connectTimeout: ApiConfig.connectTimeout,
           receiveTimeout: ApiConfig.receiveTimeout,
           sendTimeout: ApiConfig.sendTimeout,
           headers: {
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
           responseType: ResponseType.json,
         ),
       ) {
    dio.interceptors.add(_authInterceptor);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  /// Instancia de Dio ya configurada que consumen los repositorios.
  final Dio dio;

  final AuthInterceptor _authInterceptor;

  /// Registra el handler de 401 (token rechazado). Se setea despues de crear
  /// el cliente, cuando ya existe el controlador de sesion.
  set onUnauthorized(void Function()? handler) =>
      _authInterceptor.onUnauthorized = handler;

  String _serverBaseUrl;

  /// URL base del servidor actual (sin el prefijo `/api/v1`).
  String get serverBaseUrl => _serverBaseUrl;

  /// Cambia el servidor destino en caliente (afecta a los proximos requests).
  void updateServerBaseUrl(String serverBaseUrl) {
    _serverBaseUrl = serverBaseUrl;
    dio.options.baseUrl = ApiConfig.apiBaseUrlFor(serverBaseUrl);
  }
}
