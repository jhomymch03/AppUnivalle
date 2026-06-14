/// Linea de tiempo del historial del expediente (replica `TimelineHistorial`).
///
/// El backend devuelve el historial en orden ascendente; aqui se muestra del
/// mas reciente al mas antiguo. El evento mas reciente se resalta.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_card.dart';
import '../../../../core/utils/formato.dart';
import '../../data/models/estado_postulacion.dart';
import '../../data/models/historial_estado.dart';

class TimelineHistorial extends StatelessWidget {
  const TimelineHistorial({super.key, required this.historial});

  final List<HistorialEstado> historial;

  String _etiquetaEstado(String wire) {
    try {
      return EstadoPostulacion.fromWire(wire).label;
    } catch (_) {
      return wire;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventos = historial.reversed.toList();

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
                child: const Icon(Icons.timeline_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seguimiento del trámite',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (eventos.isEmpty)
            Text(
              'Aún no hay movimientos. Cuando envíes tu postulación, verás aquí cada paso.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            )
          else
            for (var i = 0; i < eventos.length; i++)
              _EventoFila(
                etiqueta: _etiquetaEstado(eventos[i].estadoNuevo),
                subtitulo:
                    '${etiquetaRol(eventos[i].actorRol)} · ${fechaRelativa(eventos[i].createdAt)}',
                motivo: eventos[i].motivo,
                esReciente: i == 0,
                esUltimo: i == eventos.length - 1,
              ),
        ],
      ),
    );
  }
}

/// Una fila del timeline: riel (punto + linea) a la izquierda + contenido.
class _EventoFila extends StatelessWidget {
  const _EventoFila({
    required this.etiqueta,
    required this.subtitulo,
    required this.motivo,
    required this.esReciente,
    required this.esUltimo,
  });

  final String etiqueta;
  final String subtitulo;
  final String? motivo;
  final bool esReciente;
  final bool esUltimo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Riel: pequeño tramo, punto, y linea hasta el siguiente evento.
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                _Punto(esReciente: esReciente),
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.borde,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Contenido del evento.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: esReciente ? AppColors.primary : AppColors.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  if (motivo != null && motivo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.superficieSutil,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          motivo!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto del riel: relleno carmesi para el evento mas reciente; con borde para
/// los anteriores.
class _Punto extends StatelessWidget {
  const _Punto({required this.esReciente});

  final bool esReciente;

  @override
  Widget build(BuildContext context) {
    if (esReciente) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.rosaContenedor, width: 3),
        ),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borde, width: 2),
      ),
    );
  }
}
