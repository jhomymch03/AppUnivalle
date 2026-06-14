// lib/features/postulaciones/application/resolucion_carta.dart
/// Mapea el estado de la postulacion a la "resolucion" mostrada en Carta de
/// Respuesta (espeja `CartaRespuesta.vue` del web). La fecha concreta la elige
/// la UI segun el tipo; aqui solo va el texto y el tipo (para icono/color).
library;

import '../data/models/estado_postulacion.dart';

enum TipoResolucion { aprobado, rechazado, observado }

class ResolucionCarta {
  const ResolucionCarta({
    required this.tipo,
    required this.titulo,
    required this.proximoPaso,
  });

  final TipoResolucion tipo;
  final String titulo;
  final String proximoPaso;
}

/// `null` si el estado todavia no tiene una resolucion que mostrar.
ResolucionCarta? resolucionDeCarta(EstadoPostulacion estado) {
  switch (estado) {
    case EstadoPostulacion.aprobado:
      return const ResolucionCarta(
        tipo: TipoResolucion.aprobado,
        titulo: 'Propuesta aprobada',
        proximoPaso: 'Continuar al Módulo 2.',
      );
    case EstadoPostulacion.rechazado:
      return const ResolucionCarta(
        tipo: TipoResolucion.rechazado,
        titulo: 'Propuesta rechazada',
        proximoPaso: 'Generar una nueva postulación.',
      );
    case EstadoPostulacion.observadoSecretaria:
    case EstadoPostulacion.observadoDireccion:
      return const ResolucionCarta(
        tipo: TipoResolucion.observado,
        titulo: 'Propuesta observada',
        proximoPaso: 'Corregir y reenviar el expediente.',
      );
    case EstadoPostulacion.borrador:
    case EstadoPostulacion.enviadoASecretaria:
    case EstadoPostulacion.enRevisionDireccionCat:
    case EstadoPostulacion.pausadoPorAbandono:
      return null;
  }
}
