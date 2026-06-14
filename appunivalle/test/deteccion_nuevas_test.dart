// test/deteccion_nuevas_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/notificaciones/data/models/notificacion.dart';
import 'package:appunivalle/features/notificaciones/application/deteccion_nuevas.dart';

Notificacion _n(String id) => Notificacion(
      id: id,
      tipo: 'aprobada',
      titulo: 't',
      mensaje: 'm',
      leida: false,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('devuelve solo los ids no vistos', () {
    final nuevas = idsNuevas({'a', 'b'}, [_n('b'), _n('c'), _n('d')]);
    expect(nuevas, {'c', 'd'});
  });

  test('vacio si no hay nuevos', () {
    expect(idsNuevas({'a', 'b'}, [_n('a'), _n('b')]), isEmpty);
  });
}
