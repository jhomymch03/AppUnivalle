/// Panel de observaciones agrupadas por ronda (replica `ObservacionesPanel`).
///
/// Solo muestra las visibles al estudiante. La ronda mas reciente arriba; las
/// no respondidas se destacan, las respondidas llevan check.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_card.dart';
import '../../../../core/utils/formato.dart';
import '../../data/models/observacion.dart';

/// Tonos para el estado "respondida" (verde) — coherentes con EstadoBadge.
const _verdeBg = Color(0xFFD1FAE5);
const _verdeFg = Color(0xFF047857);

/// Tonos para el estado "pendiente" (ambar) — coherentes con EstadoBadge.
const _ambarBg = Color(0xFFFEF3C7);
const _ambarFg = Color(0xFFB45309);

class ObservacionesPanel extends StatelessWidget {
  const ObservacionesPanel({super.key, required this.observaciones});

  final List<Observacion> observaciones;

  @override
  Widget build(BuildContext context) {
    final visibles = observaciones.where((o) => o.visibleEstudiante).toList();

    // Agrupa por ronda (desc).
    final porRonda = <int, List<Observacion>>{};
    for (final o in visibles) {
      porRonda.putIfAbsent(o.ronda, () => []).add(o);
    }
    final rondas = porRonda.keys.toList()..sort((a, b) => b.compareTo(a));

    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rosaContenedor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.forum_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Observaciones',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          if (visibles.isEmpty)
            _SinObservaciones()
          else
            for (var r = 0; r < rondas.length; r++) ...[
              if (r != 0) const SizedBox(height: 8),
              _EtiquetaRonda(ronda: rondas[r]),
              const SizedBox(height: 8),
              for (final obs in (porRonda[rondas[r]]!
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt))))
                _ObservacionTile(obs: obs),
            ],
        ],
      ),
    );
  }
}

/// Estado vacio: sin observaciones (verde, tranquilizador).
class _SinObservaciones extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _verdeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: _verdeFg, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('Sin observaciones por ahora.',
                style: TextStyle(color: _verdeFg, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// Separador de ronda.
class _EtiquetaRonda extends StatelessWidget {
  const _EtiquetaRonda({required this.ronda});

  final int ronda;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.superficieSutil,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Ronda $ronda',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.texto,
        ),
      ),
    );
  }
}

class _ObservacionTile extends StatelessWidget {
  const _ObservacionTile({required this.obs});

  final Observacion obs;

  @override
  Widget build(BuildContext context) {
    final respondida = obs.respondida;
    final acento = respondida ? _verdeFg : _ambarFg;
    final fondo = respondida ? AppColors.superficieSutil : _ambarBg;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: acento, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(etiquetaRol(obs.autorRol),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              _EstadoChip(respondida: respondida),
            ],
          ),
          const SizedBox(height: 6),
          Text(obs.contenido),
          const SizedBox(height: 6),
          Text(fechaRelativa(obs.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ],
      ),
    );
  }
}

/// Pildora "Respondida" / "Pendiente".
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.respondida});

  final bool respondida;

  @override
  Widget build(BuildContext context) {
    final bg = respondida ? _verdeBg : _ambarBg;
    final fg = respondida ? _verdeFg : _ambarFg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            respondida ? Icons.check_circle : Icons.schedule,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            respondida ? 'Respondida' : 'Pendiente',
            style: TextStyle(
                fontSize: 11, color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
