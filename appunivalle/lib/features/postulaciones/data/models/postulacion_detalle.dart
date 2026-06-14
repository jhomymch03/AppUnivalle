/// Detalle de una postulacion — espeja `PostulacionDetalleOutput`:
/// la postulacion + su historial + sus observaciones.
library;

import 'historial_estado.dart';
import 'observacion.dart';
import 'postulacion.dart';

class PostulacionDetalle {
  const PostulacionDetalle({
    required this.postulacion,
    required this.historial,
    required this.observaciones,
  });

  final Postulacion postulacion;
  final List<HistorialEstado> historial;
  final List<Observacion> observaciones;

  factory PostulacionDetalle.fromJson(Map<String, dynamic> json) {
    final historialRaw = json['historial'] as List<dynamic>? ?? const [];
    final observacionesRaw = json['observaciones'] as List<dynamic>? ?? const [];
    return PostulacionDetalle(
      postulacion: Postulacion.fromJson(json),
      historial: historialRaw
          .map((e) => HistorialEstado.fromJson(e as Map<String, dynamic>))
          .toList(),
      observaciones: observacionesRaw
          .map((e) => Observacion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
