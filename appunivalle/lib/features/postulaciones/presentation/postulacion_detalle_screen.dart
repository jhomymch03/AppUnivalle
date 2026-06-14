/// Detalle de una postulacion (Fase B, solo lectura).
///
/// Reune la misma informacion que el web: estado + banner + stepper, datos
/// generales, documentos (presencia), observaciones e historial.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/postulacion.dart';
import '../data/models/postulacion_detalle.dart';
import '../data/models/tipo_tutor.dart';
import 'widgets/documentos_seccion.dart';
import 'widgets/estado_badge.dart';
import 'widgets/estado_banner.dart';
import 'widgets/observaciones_panel.dart';
import 'widgets/stepper_proceso.dart';
import 'widgets/timeline_historial.dart';

class PostulacionDetalleScreen extends StatefulWidget {
  const PostulacionDetalleScreen({super.key, required this.id});

  final String id;

  @override
  State<PostulacionDetalleScreen> createState() =>
      _PostulacionDetalleScreenState();
}

class _PostulacionDetalleScreenState extends State<PostulacionDetalleScreen> {
  late Future<PostulacionDetalle> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<PostulacionDetalle> _cargar() => context
      .read<AppDependencies>()
      .postulacionesRepository
      .obtenerDetalle(widget.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: const [NotificationsBell()],
      ),
      body: FutureBuilder<PostulacionDetalle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : 'No se pudo cargar el detalle.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          setState(() => _future = _cargar()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detalle = snapshot.data!;
          final p = detalle.postulacion;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.titulo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  EstadoBadge(estado: p.estado),
                ],
              ),
              const SizedBox(height: 12),
              EstadoBanner(estado: p.estado, motivoRechazo: p.motivoRechazo),
              const SizedBox(height: 12),
              StepperProceso(estado: p.estado),
              const SizedBox(height: 12),
              _InfoGeneral(postulacion: p),
              const SizedBox(height: 12),
              DocumentosSeccion(postulacion: p),
              const SizedBox(height: 12),
              ObservacionesPanel(observaciones: detalle.observaciones),
              const SizedBox(height: 12),
              TimelineHistorial(historial: detalle.historial),
            ],
          );
        },
      ),
    );
  }
}

class _InfoGeneral extends StatelessWidget {
  const _InfoGeneral({required this.postulacion});

  final Postulacion postulacion;

  @override
  Widget build(BuildContext context) {
    final p = postulacion;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información general',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _Campo(label: 'Modalidad', valor: p.modalidad),
            _Campo(label: 'Tipo de tutor', valor: p.tipoTutor.label),
            if (p.tipoTutor == TipoTutor.externo &&
                p.tutorExternoNombreCompleto.isNotEmpty)
              _Campo(
                label: 'Tutor externo',
                valor: p.tutorExternoEmail != null
                    ? '${p.tutorExternoNombreCompleto} · ${p.tutorExternoEmail}'
                    : p.tutorExternoNombreCompleto,
              ),
            _Campo(label: 'Descripción', valor: p.descripcion),
            if (p.justificacion != null && p.justificacion!.isNotEmpty)
              _Campo(label: 'Justificación', valor: p.justificacion!),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.label, required this.valor});
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(valor),
        ],
      ),
    );
  }
}
