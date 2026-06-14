/// Perfil del usuario autenticado — respuesta de `GET /api/v1/auth/me`.
///
/// Espeja `UsuarioMeOutput` del backend:
///   {
///     "id": "uuid", "email": "...", "nombres": "...", "apellidos": "...",
///     "rol": "estudiante", "telefono": null,
///     "ultimo_login": "2026-06-12T10:00:00Z", "activo": true
///   }
library;

import 'rol_usuario.dart';

class UsuarioMe {
  const UsuarioMe({
    required this.id,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    required this.activo,
    this.telefono,
    this.ultimoLogin,
  });

  /// UUID del usuario (string).
  final String id;
  final String email;
  final String nombres;
  final String apellidos;
  final RolUsuario rol;
  final bool activo;
  final String? telefono;
  final DateTime? ultimoLogin;

  /// Nombre completo para mostrar en UI.
  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory UsuarioMe.fromJson(Map<String, dynamic> json) {
    final ultimoLoginRaw = json['ultimo_login'] as String?;
    return UsuarioMe(
      id: json['id'] as String,
      email: json['email'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      rol: RolUsuario.fromWire(json['rol'] as String),
      activo: json['activo'] as bool,
      telefono: json['telefono'] as String?,
      ultimoLogin:
          ultimoLoginRaw != null ? DateTime.parse(ultimoLoginRaw) : null,
    );
  }
}
