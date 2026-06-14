// lib/features/postulaciones/application/postulacion_actual.dart
/// Helpers puros sobre la lista de postulaciones del estudiante.
///
/// Replican la convencion del web (`usePostulacionActual`): existe UNA
/// postulacion "activa" — la mas reciente que NO esta rechazada. Y solo
/// ciertos estados son editables.
library;

import '../data/models/estado_postulacion.dart';
import '../data/models/postulacion.dart';

/// Estados en los que el formulario es editable y se puede (re)enviar.
const _estadosEditables = <EstadoPostulacion>{
  EstadoPostulacion.borrador,
  EstadoPostulacion.observadoSecretaria,
  EstadoPostulacion.observadoDireccion,
};

/// La postulacion activa: la mas reciente (por `createdAt`) que no este
/// RECHAZADA. `null` si no hay ninguna o todas estan rechazadas.
Postulacion? pickActiva(List<Postulacion> items) {
  final candidatas = items
      .where((p) => p.estado != EstadoPostulacion.rechazado)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return candidatas.isEmpty ? null : candidatas.first;
}

/// `true` si en ese estado el estudiante puede editar y (re)enviar.
bool esEditable(EstadoPostulacion estado) => _estadosEditables.contains(estado);

/// Postulacion a destacar en el Home ("Tu postulación más reciente").
///
/// Prioridad: si el estudiante tiene alguna APROBADA, se muestra esa (la mas
/// reciente aprobada, por `updatedAt`). Si no hay ninguna aprobada, se muestra
/// la mas reciente en general (por `updatedAt`), aunque este rechazada.
/// `null` solo si no tiene ninguna postulacion.
Postulacion? pickResumenHome(List<Postulacion> items) {
  if (items.isEmpty) return null;

  final aprobadas = items
      .where((p) => p.estado == EstadoPostulacion.aprobado)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  if (aprobadas.isNotEmpty) return aprobadas.first;

  final porFecha = [...items]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return porFecha.first;
}
