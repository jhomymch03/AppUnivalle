// test/modalidades_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/catalogos/data/modalidades_repository.dart';

void main() {
  test('mapea nombres del backend', () {
    final nombres = modalidadesDesdeJson([
      {'codigo': 'TES', 'nombre': 'Tesis', 'activa': true},
      {'codigo': 'PG', 'nombre': 'Proyecto de grado', 'activa': true},
    ]);
    expect(nombres, ['Tesis', 'Proyecto de grado']);
  });

  test('lista vacia -> usa el fallback', () {
    expect(modalidadesDesdeJson(const []), kModalidadesFallback);
  });
}
