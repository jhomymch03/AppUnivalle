/// Roles del sistema, identicos al enum `RolUsuario` del backend
/// (CHECK `ck_usuarios_rol`). El valor `wire` es exactamente el string que
/// viaja en el JSON / JWT.
library;

enum RolUsuario {
  estudiante('estudiante'),
  secretaria('secretaria'),
  director('director'),
  cat('cat'),
  vicerrector('vicerrector'),
  admin('admin');

  const RolUsuario(this.wire);

  /// String tal como lo emite el backend.
  final String wire;

  /// Parsea el rol desde el string del backend. Lanza si es desconocido.
  static RolUsuario fromWire(String value) {
    return RolUsuario.values.firstWhere(
      (r) => r.wire == value,
      orElse: () => throw ArgumentError('Rol desconocido del backend: $value'),
    );
  }
}
