// Tests de parseo de los modelos de postulaciones desde el JSON del backend.

import 'package:flutter_test/flutter_test.dart';

import 'package:appunivalle/features/postulaciones/data/models/estado_postulacion.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion_detalle.dart';
import 'package:appunivalle/features/postulaciones/data/models/tipo_tutor.dart';

void main() {
  final jsonBase = <String, dynamic>{
    'id': 'abcd1234-0000-0000-0000-000000000000',
    'codigo': null,
    'estudiante_id': '11111111-1111-1111-1111-111111111111',
    'carrera_id': '22222222-2222-2222-2222-222222222222',
    'titulo': 'Sistema de gestión',
    'descripcion': 'Una descripción larga.',
    'justificacion': null,
    'modalidad': 'Tesis',
    'tipo_tutor': 'externo',
    'tutor_docente_id': null,
    'tutor_externo_nombres': 'Ana',
    'tutor_externo_apellidos': 'García',
    'tutor_externo_email': 'ana@ext.com',
    'tutor_externo_cv_archivo_id': '33333333-3333-3333-3333-333333333333',
    'tutor_externo_titulo_archivo_id': null,
    'carta_postulacion_archivo_id': null,
    'carta_postulacion_origen': 'generada_estudiante',
    'estado_actual': 'OBSERVADO_SECRETARIA',
    'motivo_rechazo': null,
    'created_at': '2026-06-01T10:00:00Z',
    'updated_at': '2026-06-05T12:30:00Z',
  };

  test('Postulacion.fromJson mapea campos y enums', () {
    final p = Postulacion.fromJson(jsonBase);

    expect(p.titulo, 'Sistema de gestión');
    expect(p.estado, EstadoPostulacion.observadoSecretaria);
    expect(p.tipoTutor, TipoTutor.externo);
    expect(p.codigoCorto, '#ABCD1234'); // codigo null -> fragmento UUID
    expect(p.tutorExternoNombreCompleto, 'Ana García');
    expect(p.cartaPostulacionArchivoId, isNull);
    expect(p.tutorExternoCvArchivoId, isNotNull);
  });

  test('PostulacionDetalle.fromJson parsea historial y observaciones', () {
    final json = {
      ...jsonBase,
      'historial': [
        {
          'id': 'h1',
          'postulacion_id': jsonBase['id'],
          'estado_anterior': 'BORRADOR',
          'estado_nuevo': 'ENVIADO_A_SECRETARIA',
          'actor_usuario_id': null,
          'actor_rol': 'estudiante',
          'motivo': null,
          'created_at': '2026-06-02T09:00:00Z',
        },
      ],
      'observaciones': [
        {
          'id': 'o1',
          'postulacion_id': jsonBase['id'],
          'autor_usuario_id': '44444444-4444-4444-4444-444444444444',
          'autor_rol': 'secretaria',
          'tipo': 'texto_libre',
          'contenido': 'Corrige el título.',
          'visible_estudiante': true,
          'ronda': 1,
          'respondida': false,
          'fecha_respuesta': null,
          'respuesta_estudiante': null,
          'fecha_respuesta_estudiante': null,
          'created_at': '2026-06-03T11:00:00Z',
        },
      ],
    };

    final d = PostulacionDetalle.fromJson(json);

    expect(d.postulacion.estado, EstadoPostulacion.observadoSecretaria);
    expect(d.historial, hasLength(1));
    expect(d.historial.first.estadoNuevo, 'ENVIADO_A_SECRETARIA');
    expect(d.observaciones, hasLength(1));
    expect(d.observaciones.first.autorRol, 'secretaria');
    expect(d.observaciones.first.respondida, isFalse);
  });
}
