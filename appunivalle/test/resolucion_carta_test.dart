// test/resolucion_carta_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/estado_postulacion.dart';
import 'package:appunivalle/features/postulaciones/application/resolucion_carta.dart';

void main() {
  test('aprobado / rechazado / observado tienen resolucion', () {
    expect(resolucionDeCarta(EstadoPostulacion.aprobado)?.tipo,
        TipoResolucion.aprobado);
    expect(resolucionDeCarta(EstadoPostulacion.rechazado)?.tipo,
        TipoResolucion.rechazado);
    expect(resolucionDeCarta(EstadoPostulacion.observadoSecretaria)?.tipo,
        TipoResolucion.observado);
    expect(resolucionDeCarta(EstadoPostulacion.observadoDireccion)?.tipo,
        TipoResolucion.observado);
  });

  test('estados sin resolucion devuelven null', () {
    expect(resolucionDeCarta(EstadoPostulacion.borrador), isNull);
    expect(resolucionDeCarta(EstadoPostulacion.enviadoASecretaria), isNull);
    expect(resolucionDeCarta(EstadoPostulacion.enRevisionDireccionCat), isNull);
  });
}
