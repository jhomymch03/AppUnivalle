// test/postulacion_actual_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/estado_postulacion.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion.dart';
import 'package:appunivalle/features/postulaciones/application/postulacion_actual.dart';

Postulacion _p({required String id, required String estado, required String createdAt}) {
  return Postulacion.fromJson({
    'id': id,
    'codigo': null,
    'titulo': 'T',
    'descripcion': 'Una descripcion larga.',
    'modalidad': 'Tesis',
    'tipo_tutor': 'interno',
    'estado_actual': estado,
    'created_at': createdAt,
    'updated_at': createdAt,
  });
}

void main() {
  test('pickActiva devuelve la mas reciente no rechazada', () {
    final lista = [
      _p(id: 'a', estado: 'BORRADOR', createdAt: '2026-01-01T00:00:00Z'),
      _p(id: 'b', estado: 'OBSERVADO_SECRETARIA', createdAt: '2026-03-01T00:00:00Z'),
      _p(id: 'c', estado: 'RECHAZADO', createdAt: '2026-06-01T00:00:00Z'),
    ];
    expect(pickActiva(lista)?.id, 'b');
  });

  test('pickActiva devuelve null si todas estan rechazadas o no hay', () {
    expect(pickActiva(const []), isNull);
    expect(
      pickActiva([_p(id: 'a', estado: 'RECHAZADO', createdAt: '2026-01-01T00:00:00Z')]),
      isNull,
    );
  });

  test('esEditable solo en BORRADOR / OBSERVADO_*', () {
    expect(esEditable(EstadoPostulacion.borrador), isTrue);
    expect(esEditable(EstadoPostulacion.observadoSecretaria), isTrue);
    expect(esEditable(EstadoPostulacion.observadoDireccion), isTrue);
    expect(esEditable(EstadoPostulacion.enviadoASecretaria), isFalse);
    expect(esEditable(EstadoPostulacion.aprobado), isFalse);
  });

  group('pickResumenHome', () {
    test('prioriza la APROBADA aunque haya una rechazada mas reciente', () {
      final lista = [
        _p(id: 'aprob', estado: 'APROBADO', createdAt: '2026-02-01T00:00:00Z'),
        _p(id: 'rech', estado: 'RECHAZADO', createdAt: '2026-06-01T00:00:00Z'),
      ];
      expect(pickResumenHome(lista)?.id, 'aprob');
    });

    test('sin aprobadas, devuelve la mas reciente (aunque este rechazada)', () {
      final lista = [
        _p(id: 'vieja', estado: 'BORRADOR', createdAt: '2026-01-01T00:00:00Z'),
        _p(id: 'rech', estado: 'RECHAZADO', createdAt: '2026-06-01T00:00:00Z'),
      ];
      expect(pickResumenHome(lista)?.id, 'rech');
    });

    test('con varias aprobadas, devuelve la aprobada mas reciente', () {
      final lista = [
        _p(id: 'a1', estado: 'APROBADO', createdAt: '2026-01-01T00:00:00Z'),
        _p(id: 'a2', estado: 'APROBADO', createdAt: '2026-05-01T00:00:00Z'),
      ];
      expect(pickResumenHome(lista)?.id, 'a2');
    });

    test('lista vacia devuelve null', () {
      expect(pickResumenHome(const []), isNull);
    });
  });
}
