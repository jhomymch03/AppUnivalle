// lib/features/postulaciones/presentation/historial_screen.dart
/// Pantalla "Historial / Trazabilidad": por cada postulacion del estudiante
/// (vigente, observadas, rechazadas, historicas) muestra su cabecera y el
/// timeline de estados. Espeja `estudiante/Historial.vue`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/hero_header.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/historial_estado.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';
import 'widgets/timeline_historial.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<({Postulacion p, List<HistorialEstado> historial})>> _carga;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<List<({Postulacion p, List<HistorialEstado> historial})>>
      _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final activa = pickActiva(lista);
    final res = <({Postulacion p, List<HistorialEstado> historial})>[];
    for (final p in lista) {
      final detalle = await deps.postulacionesRepository.obtenerDetalle(p.id);
      res.add((p: p, historial: detalle.historial));
    }
    // Marca interna de "vigente" la calcula el build comparando con activa.id.
    _activaId = activa?.id;
    return res;
  }

  String? _activaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Historial'),
        actions: const [NotificationsBell()],
      ),
      body: FutureBuilder<
          List<({Postulacion p, List<HistorialEstado> historial})>>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudo cargar el historial.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    const Text('Todavía no creaste ninguna postulación.'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/postulacion/nueva'),
                      child: const Text('Ir a Nueva postulación'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const HeroHeader(
                titulo: 'Historial',
                subtitulo: 'Trazabilidad de tus postulaciones',
              ),
              const SizedBox(height: 20),
              for (final item in items) _seccion(context, item),
            ],
          );
        },
      ),
    );
  }

  Widget _seccion(
    BuildContext context,
    ({Postulacion p, List<HistorialEstado> historial}) item,
  ) {
    final vigente = item.p.id == _activaId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(item.p.codigoCorto,
                              style: Theme.of(context).textTheme.bodySmall),
                          if (vigente) ...[
                            const SizedBox(width: 8),
                            const _PildoraVigente(),
                          ],
                        ],
                      ),
                    ),
                    EstadoBadge(estado: item.p.estado),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.p.titulo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${item.p.modalidad} · ${item.p.tipoTutor.label} · Creada ${formatFecha(item.p.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TimelineHistorial(historial: item.historial),
        ],
      ),
    );
  }
}

/// Pildora "Vigente" con el estilo carmesi suave de la app.
class _PildoraVigente extends StatelessWidget {
  const _PildoraVigente();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.rosaContenedor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Vigente',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
