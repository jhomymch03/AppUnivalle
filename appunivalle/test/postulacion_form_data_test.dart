// test/postulacion_form_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/tipo_tutor.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion_form_data.dart';

void main() {
  PostulacionFormData base() => PostulacionFormData(
        titulo: 'Sistema de gestion academica',
        descripcion: 'Descripcion suficientemente larga.',
        modalidad: 'Tesis',
        tipoTutor: TipoTutor.interno,
        tutorDocenteId: 'doc-1',
      );

  test('valida titulo, descripcion y modalidad', () {
    final f = base()..titulo = 'abc'; // < 5
    final e = f.validar();
    expect(e['titulo'], isNotNull);
  });

  test('interno requiere docente', () {
    final f = base()..tutorDocenteId = null;
    expect(f.validar()['tutorDocenteId'], isNotNull);
  });

  test('externo requiere nombres y apellidos', () {
    final f = PostulacionFormData(
      titulo: 'Titulo valido',
      descripcion: 'Descripcion larga valida.',
      modalidad: 'Tesis',
      tipoTutor: TipoTutor.externo,
    );
    final e = f.validar();
    expect(e['tutorExternoNombres'], isNotNull);
    expect(e['tutorExternoApellidos'], isNotNull);
  });

  test('toJson interno limpia los campos de tutor externo', () {
    final f = base()..tutorDocenteId = 'doc-9';
    final json = f.toJson();
    expect(json['tipo_tutor'], 'interno');
    expect(json['tutor_docente_id'], 'doc-9');
    expect(json['tutor_externo_nombres'], isNull);
    expect(json['tutor_externo_cv_archivo_id'], isNull);
  });

  test('toJson externo limpia tutor_docente_id', () {
    final f = PostulacionFormData(
      titulo: 'Titulo valido',
      descripcion: 'Descripcion larga valida.',
      modalidad: 'Tesis',
      tipoTutor: TipoTutor.externo,
      tutorExternoNombres: 'Ana',
      tutorExternoApellidos: 'Garcia',
      tutorExternoCvArchivoId: 'cv-1',
    );
    final json = f.toJson();
    expect(json['tipo_tutor'], 'externo');
    expect(json['tutor_docente_id'], isNull);
    expect(json['tutor_externo_nombres'], 'Ana');
    expect(json['tutor_externo_cv_archivo_id'], 'cv-1');
  });
}
