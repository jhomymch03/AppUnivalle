/// Barra de progreso de 4 pasos del tramite (replica `StepperProceso` del web).
///
/// Proyecta el estado actual sobre: Borrador -> Secretaría -> Dirección y CAT
/// -> Resultado. No reimplementa la maquina de estados (vive en el backend);
/// solo la muestra para orientar al estudiante.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_card.dart';
import '../../data/models/estado_postulacion.dart';

enum _Variante { activo, observado, aprobado, rechazado, pausado }

class StepperProceso extends StatelessWidget {
  const StepperProceso({super.key, required this.estado});

  final EstadoPostulacion estado;

  static const _pasos = ['Borrador', 'Secretaría', 'Dirección y CAT', 'Resultado'];

  ({int index, _Variante variante}) get _info {
    switch (estado) {
      case EstadoPostulacion.borrador:
        return (index: 0, variante: _Variante.activo);
      case EstadoPostulacion.enviadoASecretaria:
        return (index: 1, variante: _Variante.activo);
      case EstadoPostulacion.observadoSecretaria:
        return (index: 1, variante: _Variante.observado);
      case EstadoPostulacion.enRevisionDireccionCat:
        return (index: 2, variante: _Variante.activo);
      case EstadoPostulacion.observadoDireccion:
        return (index: 2, variante: _Variante.observado);
      case EstadoPostulacion.aprobado:
        return (index: 3, variante: _Variante.aprobado);
      case EstadoPostulacion.rechazado:
        return (index: 3, variante: _Variante.rechazado);
      case EstadoPostulacion.pausadoPorAbandono:
        return (index: 2, variante: _Variante.pausado);
    }
  }

  /// Color del paso actual segun su variante.
  Color _colorVariante(_Variante v) {
    return switch (v) {
      _Variante.activo => AppColors.primary,
      _Variante.observado => const Color(0xFFF59E0B),
      _Variante.aprobado => const Color(0xFF059669),
      _Variante.rechazado => const Color(0xFFE11D48),
      _Variante.pausado => const Color(0xFF94A3B8),
    };
  }

  Color _colorCirculo(int i) {
    final info = _info;
    if (i < info.index) return AppColors.primary; // completado
    if (i == info.index) return _colorVariante(info.variante);
    return AppColors.superficieSutil; // pendiente
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

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
              Text(
                'Progreso del trámite',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < _pasos.length; i++) ...[
                _Circulo(
                  numero: i + 1,
                  completado: i < info.index,
                  color: _colorCirculo(i),
                  activo: i <= info.index,
                ),
                if (i < _pasos.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i < info.index
                            ? AppColors.primary
                            : AppColors.borde,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _pasos.length; i++)
                Expanded(
                  child: Text(
                    _pasos[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: i <= info.index
                          ? AppColors.texto
                          : Theme.of(context).colorScheme.outline,
                      fontWeight:
                          i <= info.index ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
          if (info.variante == _Variante.pausado) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.superficieSutil,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.pause_circle_outline,
                      size: 18, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El trámite está en pausa. Contacta con secretaría para reactivarlo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo({
    required this.numero,
    required this.completado,
    required this.color,
    required this.activo,
  });

  final int numero;
  final bool completado;
  final Color color;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: activo
            ? null
            : Border.all(color: AppColors.borde, width: 1.5),
      ),
      alignment: Alignment.center,
      child: completado
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '$numero',
              style: TextStyle(
                color: activo
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
    );
  }
}
