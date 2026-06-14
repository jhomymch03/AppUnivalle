// lib/features/catalogos/data/models/tutor_option.dart
/// Opcion de tutor interno para el selector. Igual que el composable
/// `useTutoresHabilitados` del web: cruza `GET /tutores-habilitados` (que solo
/// trae `docente_id`) con `GET /docentes` (que trae el nombre) y arma el label.
library;

class TutorOption {
  const TutorOption({
    required this.docenteId,
    required this.nombreCompleto,
    this.especialidad,
  });

  /// UUID del docente: es lo que va en `tutor_docente_id` del payload.
  final String docenteId;
  final String nombreCompleto;
  final String? especialidad;
}

/// Cruza tutores habilitados (activos) con el catalogo de docentes y devuelve
/// las opciones ordenadas por nombre. Descarta habilitados inactivos o sin
/// docente correspondiente.
List<TutorOption> construirOpcionesTutor(
  List<Map<String, dynamic>> habilitados,
  List<Map<String, dynamic>> docentes,
) {
  final docMap = {for (final d in docentes) d['id'] as String: d};
  final opciones = <TutorOption>[];
  for (final h in habilitados) {
    if (h['activo'] != true) continue;
    final doc = docMap[h['docente_id'] as String?];
    if (doc == null) continue;
    opciones.add(TutorOption(
      docenteId: doc['id'] as String,
      nombreCompleto: '${doc['nombres']} ${doc['apellidos']}',
      especialidad: doc['especialidad'] as String?,
    ));
  }
  opciones.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
  return opciones;
}
