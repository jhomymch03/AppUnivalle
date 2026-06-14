/// Estados de una postulacion, identicos a `EstadoPostulacion` del backend
/// (`ck_postulaciones_estado`). Cada estado trae su etiqueta legible y un
/// "tono" cromatico para el badge (replica los colores del frontend web).
library;

/// Tono cromatico del badge/banner segun el estado.
enum EstadoTono { neutro, rojo, ambar, verde }

enum EstadoPostulacion {
  borrador('BORRADOR', 'Borrador', EstadoTono.neutro),
  enviadoASecretaria('ENVIADO_A_SECRETARIA', 'Nuevo', EstadoTono.rojo),
  observadoSecretaria('OBSERVADO_SECRETARIA', 'Observado (secretaría)', EstadoTono.ambar),
  enRevisionDireccionCat('EN_REVISION_DIRECCION_CAT', 'En revisión', EstadoTono.neutro),
  observadoDireccion('OBSERVADO_DIRECCION', 'Observado (dirección)', EstadoTono.ambar),
  aprobado('APROBADO', 'Aprobado', EstadoTono.verde),
  rechazado('RECHAZADO', 'Rechazado', EstadoTono.rojo),
  pausadoPorAbandono('PAUSADO_POR_ABANDONO', 'Pausado', EstadoTono.neutro);

  const EstadoPostulacion(this.wire, this.label, this.tono);

  /// Valor literal tal como lo emite el backend.
  final String wire;

  /// Etiqueta corta para mostrar en UI.
  final String label;

  /// Tono cromatico asociado.
  final EstadoTono tono;

  static EstadoPostulacion fromWire(String value) {
    return EstadoPostulacion.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('Estado desconocido del backend: $value'),
    );
  }
}
