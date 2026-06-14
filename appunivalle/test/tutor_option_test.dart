// test/tutor_option_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/catalogos/data/models/tutor_option.dart';

void main() {
  test('construye opciones cruzando habilitados con docentes', () {
    final habilitados = [
      {'docente_id': 'd1', 'activo': true},
      {'docente_id': 'd2', 'activo': false}, // inactivo -> descartado
      {'docente_id': 'd3', 'activo': true}, // sin match en docentes -> descartado
    ];
    final docentes = [
      {'id': 'd1', 'nombres': 'Ana', 'apellidos': 'Garcia', 'especialidad': 'IA'},
      {'id': 'd2', 'nombres': 'Luis', 'apellidos': 'Perez', 'especialidad': null},
    ];

    final ops = construirOpcionesTutor(habilitados, docentes);

    expect(ops, hasLength(1));
    expect(ops.first.docenteId, 'd1');
    expect(ops.first.nombreCompleto, 'Ana Garcia');
  });
}
