/// Una transicion de estado del expediente — espeja `HistorialEstadoOutput`.
library;

class HistorialEstado {
  const HistorialEstado({
    required this.id,
    required this.estadoNuevo,
    required this.createdAt,
    this.estadoAnterior,
    this.actorRol,
    this.motivo,
  });

  final String id;
  final String? estadoAnterior;
  final String estadoNuevo;
  final String? actorRol;
  final String? motivo;
  final DateTime createdAt;

  factory HistorialEstado.fromJson(Map<String, dynamic> json) {
    return HistorialEstado(
      id: json['id'] as String,
      estadoAnterior: json['estado_anterior'] as String?,
      estadoNuevo: json['estado_nuevo'] as String,
      actorRol: json['actor_rol'] as String?,
      motivo: json['motivo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
