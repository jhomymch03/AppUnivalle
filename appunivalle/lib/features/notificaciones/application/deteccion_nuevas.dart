// lib/features/notificaciones/application/deteccion_nuevas.dart
/// Devuelve los ids de notificaciones presentes en [actuales] que no estaban
/// en [vistas]. Usado por el controller para decidir cuales avisar (sonido).
library;

import '../data/models/notificacion.dart';

Set<String> idsNuevas(Set<String> vistas, List<Notificacion> actuales) {
  return actuales
      .map((n) => n.id)
      .where((id) => !vistas.contains(id))
      .toSet();
}
