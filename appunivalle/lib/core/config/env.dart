/// Configuracion de entorno de la app.
///
/// Centraliza lo que cambia entre redes/despliegues (URL base del servidor,
/// prefijo de version, timeouts).
///
/// La URL base ahora es **editable en tiempo de ejecucion** desde la propia
/// app (pantalla de Configuracion -> Servidor), persistida en
/// [ServerConfigStore]. Esta clase solo aporta:
///   - [defaultBaseUrl]: el valor inicial / fallback cuando el usuario aun no
///     configuro nada. Se puede fijar al compilar con
///     `--dart-define=API_BASE_URL=...`.
///   - [apiBaseUrlFor]: arma `<base>/api/v1` a partir de cualquier base
///     (una IP LAN `http://192.168.x.x:8000` o una URL de Cloudflare Tunnel
///     `https://algo.trycloudflare.com`).
///
/// Nunca se hardcodea `localhost`: en un telefono fisico apuntaria al
/// telefono mismo, no a tu PC.
library;

class ApiConfig {
  const ApiConfig._();

  /// Fallback usado si NO se pasa `--dart-define=API_BASE_URL` y el usuario
  /// aun no configuro una URL en la app. Pensado para red local; lo normal
  /// es sobreescribirlo desde la pantalla de Configuracion del telefono.
  static const String _fallbackBaseUrl = 'http://192.168.0.9:8000';

  /// URL base por defecto (compile-time). Es solo el punto de partida: el
  /// usuario puede cambiarla en caliente desde la app.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _fallbackBaseUrl,
  );

  /// Prefijo comun de todos los endpoints versionados del backend.
  static const String apiPrefix = '/api/v1';

  /// Normaliza una base de servidor y le añade el prefijo de API.
  ///
  /// Quita espacios y barras finales para evitar `//api/v1`. Ej.:
  ///   `https://algo.trycloudflare.com/` -> `https://algo.trycloudflare.com/api/v1`
  static String apiBaseUrlFor(String serverBaseUrl) {
    final base = serverBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base$apiPrefix';
  }

  /// `true` si la cadena luce como una base de servidor valida (http/https).
  static bool looksLikeValidBaseUrl(String value) {
    final v = value.trim();
    final uri = Uri.tryParse(v);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Timeout para establecer la conexion (handshake).
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Timeout para recibir la respuesta completa.
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Timeout para enviar el cuerpo del request (uploads).
  static const Duration sendTimeout = Duration(seconds: 30);
}
