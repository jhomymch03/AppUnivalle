/// Almacenamiento seguro del JWT.
///
/// Envuelve `flutter_secure_storage` (Keychain en iOS, EncryptedSharedPrefs
/// en Android) para guardar el access token fuera del alcance de otras apps.
/// Es la unica puerta de acceso al token: el interceptor lo lee de aqui y el
/// repositorio de auth lo escribe/borra en login/logout.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kAccessToken = 'access_token';

  /// Guarda el access token tras un login exitoso.
  Future<void> saveToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  /// Devuelve el access token guardado, o `null` si no hay sesion.
  Future<String?> readToken() => _storage.read(key: _kAccessToken);

  /// Borra el token (logout o respuesta 401).
  Future<void> clear() => _storage.delete(key: _kAccessToken);

  /// `true` si hay un token persistido (sesion potencialmente activa).
  Future<bool> hasToken() async => (await readToken()) != null;
}
