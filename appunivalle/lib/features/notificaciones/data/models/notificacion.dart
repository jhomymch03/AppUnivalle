// lib/features/notificaciones/data/models/notificacion.dart
/// Notificacion in-app — espeja `NotificacionOutput` del backend (solo los
/// campos que la app usa).
library;

class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.createdAt,
    this.postulacionId,
  });

  final String id;
  final String? postulacionId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime createdAt;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as String,
      postulacionId: json['postulacion_id'] as String?,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      leida: json['leida'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
