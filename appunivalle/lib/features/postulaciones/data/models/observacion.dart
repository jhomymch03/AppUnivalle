/// Observacion sobre una postulacion — espeja `ObservacionOutput`.
///
/// Solo se muestran al estudiante las que tienen `visibleEstudiante == true`.
/// Se agrupan por `ronda` (cada ciclo de revision). `respondida` lo marca el
/// backend cuando el estudiante reenvia tras corregir.
library;

class Observacion {
  const Observacion({
    required this.id,
    required this.autorRol,
    required this.tipo,
    required this.contenido,
    required this.visibleEstudiante,
    required this.ronda,
    required this.respondida,
    required this.createdAt,
    this.respuestaEstudiante,
    this.fechaRespuesta,
  });

  final String id;
  final String autorRol;
  final String tipo;
  final String contenido;
  final bool visibleEstudiante;
  final int ronda;
  final bool respondida;
  final String? respuestaEstudiante;
  final DateTime? fechaRespuesta;
  final DateTime createdAt;

  factory Observacion.fromJson(Map<String, dynamic> json) {
    final fechaResp = json['fecha_respuesta'] as String?;
    return Observacion(
      id: json['id'] as String,
      autorRol: json['autor_rol'] as String,
      tipo: json['tipo'] as String,
      contenido: json['contenido'] as String,
      visibleEstudiante: json['visible_estudiante'] as bool,
      ronda: (json['ronda'] as num).toInt(),
      respondida: json['respondida'] as bool,
      respuestaEstudiante: json['respuesta_estudiante'] as String?,
      fechaRespuesta: fechaResp != null ? DateTime.parse(fechaResp) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
