// test/tipo_notificacion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/notificaciones/application/tipo_notificacion.dart';

void main() {
  test('tipo conocido devuelve su icono', () {
    expect(estiloNotificacion('aprobada').icon, Icons.check_circle);
    expect(estiloNotificacion('rechazada').icon, Icons.cancel);
    expect(estiloNotificacion('observacion_recibida').icon, Icons.comment);
  });

  test('tipo desconocido cae al fallback', () {
    expect(estiloNotificacion('algo_raro').icon, Icons.notifications);
  });
}
