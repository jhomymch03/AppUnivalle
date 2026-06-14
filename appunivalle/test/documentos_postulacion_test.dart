// test/documentos_postulacion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion.dart';
import 'package:appunivalle/features/archivos/application/documentos_postulacion.dart';

Postulacion _p(Map<String, dynamic> extra) => Postulacion.fromJson({
      'id': 'p1',
      'titulo': 'T',
      'descripcion': 'Descripcion larga.',
      'modalidad': 'Tesis',
      'tipo_tutor': 'externo',
      'estado_actual': 'BORRADOR',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      ...extra,
    });

void main() {
  test('lista solo los documentos presentes con su etiqueta', () {
    final p = _p({
      'tutor_externo_cv_archivo_id': 'cv-1',
      'tutor_externo_titulo_archivo_id': null,
      'carta_postulacion_archivo_id': null,
    });
    final docs = documentosDePostulacion(p);
    expect(docs, hasLength(1));
    expect(docs.first.archivoId, 'cv-1');
    expect(docs.first.label, 'CV del tutor');
  });

  test('sin documentos -> lista vacia', () {
    expect(documentosDePostulacion(_p(const {})), isEmpty);
  });
}
