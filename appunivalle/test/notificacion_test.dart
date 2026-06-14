// test/notificacion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/notificaciones/data/models/notificacion.dart';

void main() {
  test('Notificacion.fromJson mapea campos', () {
    final n = Notificacion.fromJson({
      'id': 'n1',
      'destinatario_id': 'u1',
      'postulacion_id': 'p1',
      'tipo': 'aprobada',
      'titulo': 'Tu propuesta fue aprobada',
      'mensaje': 'Continúa al Módulo 2.',
      'leida': false,
      'fecha_leida': null,
      'created_at': '2026-06-10T12:00:00Z',
    });
    expect(n.id, 'n1');
    expect(n.postulacionId, 'p1');
    expect(n.tipo, 'aprobada');
    expect(n.leida, isFalse);
  });

  test('postulacion_id puede ser null', () {
    final n = Notificacion.fromJson({
      'id': 'n2',
      'destinatario_id': 'u1',
      'postulacion_id': null,
      'tipo': 'recordatorio_ventana',
      'titulo': 'Recordatorio',
      'mensaje': 'Te quedan horas.',
      'leida': true,
      'fecha_leida': '2026-06-10T13:00:00Z',
      'created_at': '2026-06-10T12:00:00Z',
    });
    expect(n.postulacionId, isNull);
    expect(n.leida, isTrue);
  });
}
