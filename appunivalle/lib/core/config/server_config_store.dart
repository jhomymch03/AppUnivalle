/// Persistencia de la URL base del servidor elegida por el usuario.
///
/// Permite cambiar a que backend apunta la app (IP de LAN o URL de Cloudflare
/// Tunnel) sin recompilar: el valor se guarda en el dispositivo y se relee al
/// arrancar. Si no hay nada guardado, la app usa [ApiConfig.defaultBaseUrl].
///
/// Se respalda en `flutter_secure_storage` (ya presente para el token) para
/// no añadir dependencias nuevas. La URL no es secreta, pero reutilizar el
/// mismo backend de storage mantiene la app simple.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServerConfigStore {
  ServerConfigStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kBaseUrl = 'server_base_url';

  /// Devuelve la URL base configurada, o `null` si el usuario no cambio nada.
  Future<String?> readBaseUrl() => _storage.read(key: _kBaseUrl);

  /// Guarda la URL base elegida por el usuario.
  Future<void> saveBaseUrl(String url) =>
      _storage.write(key: _kBaseUrl, value: url.trim());

  /// Borra la URL guardada (vuelve a usarse el default de compilacion).
  Future<void> clear() => _storage.delete(key: _kBaseUrl);
}
