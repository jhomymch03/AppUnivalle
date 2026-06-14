// test/carrera_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/catalogos/data/models/carrera.dart';

void main() {
  test('Carrera.fromJson mapea campos', () {
    final c = Carrera.fromJson({
      'id': 'c1',
      'codigo': 'INF',
      'nombre': 'Ingeniería de Sistemas',
      'facultad': 'Tecnología',
      'activa': true,
    });
    expect(c.codigo, 'INF');
    expect(c.nombre, 'Ingeniería de Sistemas');
    expect(c.facultad, 'Tecnología');
  });

  test('facultad puede ser null', () {
    final c = Carrera.fromJson({
      'id': 'c2',
      'codigo': 'MAT',
      'nombre': 'Matemática',
      'facultad': null,
      'activa': true,
    });
    expect(c.facultad, isNull);
  });
}
