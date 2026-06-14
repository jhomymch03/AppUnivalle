/// Banner con un mensaje contextual segun el estado (+ motivo de rechazo).
/// Equivale al `EstadoPostulacionBanner` del web.
library;

import 'package:flutter/material.dart';

import '../../data/models/estado_postulacion.dart';
import 'estado_badge.dart';

class EstadoBanner extends StatelessWidget {
  const EstadoBanner({super.key, required this.estado, this.motivoRechazo});

  final EstadoPostulacion estado;
  final String? motivoRechazo;

  String get _mensaje {
    switch (estado) {
      case EstadoPostulacion.borrador:
        return 'Tu postulación está en borrador. Complétala y envíala a secretaría.';
      case EstadoPostulacion.enviadoASecretaria:
        return 'Enviada a secretaría. En espera de revisión documental.';
      case EstadoPostulacion.observadoSecretaria:
        return 'Secretaría dejó observaciones. Corrige y vuelve a enviar.';
      case EstadoPostulacion.enRevisionDireccionCat:
        return 'En revisión por Dirección y CAT.';
      case EstadoPostulacion.observadoDireccion:
        return 'Dirección/CAT dejó observaciones. Corrige y vuelve a enviar.';
      case EstadoPostulacion.aprobado:
        return '¡Tu propuesta fue aprobada!';
      case EstadoPostulacion.rechazado:
        return 'Tu propuesta fue rechazada.';
      case EstadoPostulacion.pausadoPorAbandono:
        return 'Tu trámite está en pausa. Contacta con secretaría.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = coloresTono(estado.tono);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _mensaje,
            style: TextStyle(color: c.fg, fontWeight: FontWeight.w600),
          ),
          if (estado == EstadoPostulacion.rechazado &&
              motivoRechazo != null &&
              motivoRechazo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Motivo: $motivoRechazo',
              style: TextStyle(color: c.fg, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
