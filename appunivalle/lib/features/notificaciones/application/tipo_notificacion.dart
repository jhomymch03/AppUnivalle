// lib/features/notificaciones/application/tipo_notificacion.dart
/// Mapea el `tipo` de notificacion del backend a un icono + color, espejo de
/// `utils/notificaciones.ts` del web. Tipo desconocido → fallback neutro.
library;

import 'package:flutter/material.dart';

typedef EstiloNotificacion = ({IconData icon, Color color});

const _porTipo = <String, EstiloNotificacion>{
  'postulacion_enviada': (icon: Icons.send, color: Colors.blue),
  'observacion_recibida': (icon: Icons.comment, color: Colors.amber),
  'aprobada': (icon: Icons.check_circle, color: Colors.green),
  'rechazada': (icon: Icons.cancel, color: Colors.red),
  'pausada_abandono': (icon: Icons.pause_circle, color: Colors.grey),
  'ventana_1dia_reiniciada': (icon: Icons.refresh, color: Colors.purple),
  'recordatorio_ventana': (icon: Icons.schedule, color: Colors.amber),
};

const _fallback = (icon: Icons.notifications, color: Colors.grey);

EstiloNotificacion estiloNotificacion(String tipo) => _porTipo[tipo] ?? _fallback;
