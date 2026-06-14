// lib/features/postulaciones/presentation/observaciones_screen.dart
/// Pantalla "Observaciones" del estudiante. Muestra las observaciones de la
/// postulacion activa (agrupadas por ronda en ObservacionesPanel). Espeja
/// `estudiante/Observaciones.vue`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/hero_header.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/observacion.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';
import 'widgets/observaciones_panel.dart';

class ObservacionesScreen extends StatefulWidget {
  const ObservacionesScreen({super.key});

  @override
  State<ObservacionesScreen> createState() => _ObservacionesScreenState();
}

class _ObservacionesScreenState extends State<ObservacionesScreen> {
  late Future<({Postulacion? activa, List<Observacion> obs})> _carga;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<({Postulacion? activa, List<Observacion> obs})> _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    final activa = pickActiva(lista);
    if (activa == null) return (activa: null, obs: <Observacion>[]);
    final detalle =
        await deps.postulacionesRepository.obtenerDetalle(activa.id);
    return (activa: activa, obs: detalle.observaciones);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Observaciones'),
        actions: const [NotificationsBell()],
      ),
      body: FutureBuilder<({Postulacion? activa, List<Observacion> obs})>(
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
                      : 'No se pudieron cargar las observaciones.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data!;
          if (data.activa == null) {
            return _SinActiva(onIr: () => context.go('/postulacion/nueva'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const HeroHeader(
                titulo: 'Observaciones',
                subtitulo: 'Revisión de tu postulación',
              ),
              const SizedBox(height: 20),
              BrandCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data.activa!.titulo,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    EstadoBadge(estado: data.activa!.estado),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ObservacionesPanel(observaciones: data.obs),
            ],
          );
        },
      ),
    );
  }
}

class _SinActiva extends StatelessWidget {
  const _SinActiva({required this.onIr});
  final VoidCallback onIr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined,
                size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Todavía no tienes una postulación activa.'),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onIr,
                child: const Text('Ir a Nueva postulación')),
          ],
        ),
      ),
    );
  }
}
