/// Pill con la etiqueta y el color del estado (replica `EstadoBadge` del web).
library;

import 'package:flutter/material.dart';

import '../../data/models/estado_postulacion.dart';

/// Colores (fondo, texto) para cada tono.
({Color bg, Color fg}) coloresTono(EstadoTono tono) {
  switch (tono) {
    case EstadoTono.neutro:
      return (bg: const Color(0xFFE2E8F0), fg: const Color(0xFF475569));
    case EstadoTono.rojo:
      return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
    case EstadoTono.ambar:
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    case EstadoTono.verde:
      return (bg: const Color(0xFFD1FAE5), fg: const Color(0xFF047857));
  }
}

class EstadoBadge extends StatelessWidget {
  const EstadoBadge({super.key, required this.estado});

  final EstadoPostulacion estado;

  @override
  Widget build(BuildContext context) {
    final c = coloresTono(estado.tono);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado.label,
        style: TextStyle(color: c.fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
