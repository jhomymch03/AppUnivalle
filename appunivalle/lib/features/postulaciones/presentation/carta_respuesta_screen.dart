// lib/features/postulaciones/presentation/carta_respuesta_screen.dart
/// Pantalla "Carta de Respuesta": resolucion de la postulacion activa (estado,
/// motivo, fecha, proximo paso). La descarga del PDF de la carta NO existe en
/// el backend (R3 pendiente): el boton queda deshabilitado, igual que el web.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formato.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../application/resolucion_carta.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';

class CartaRespuestaScreen extends StatefulWidget {
  const CartaRespuestaScreen({super.key});

  @override
  State<CartaRespuestaScreen> createState() => _CartaRespuestaScreenState();
}

class _CartaRespuestaScreenState extends State<CartaRespuestaScreen> {
  late Future<Postulacion?> _carga;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<Postulacion?> _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    return pickActiva(lista);
  }

  ({IconData icon, Color color}) _estilo(TipoResolucion t) {
    switch (t) {
      case TipoResolucion.aprobado:
        return (icon: Icons.check_circle, color: Colors.green);
      case TipoResolucion.rechazado:
        return (icon: Icons.cancel, color: Colors.red);
      case TipoResolucion.observado:
        return (icon: Icons.comment, color: Colors.amber);
    }
  }

  DateTime? _fecha(Postulacion p, TipoResolucion t) {
    switch (t) {
      case TipoResolucion.aprobado:
        return p.fechaAprobacionFinal;
      case TipoResolucion.rechazado:
        return p.fechaRechazo;
      case TipoResolucion.observado:
        return p.updatedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Carta de Respuesta'),
        actions: const [NotificationsBell()],
      ),
      body: FutureBuilder<Postulacion?>(
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
                      : 'No se pudo cargar la resolución.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final activa = snapshot.data;
          final resolucion =
              activa == null ? null : resolucionDeCarta(activa.estado);

          if (activa == null || resolucion == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tu postulación todavía no tiene una resolución. '
                  'Te avisaremos cuando haya novedades.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final estilo = _estilo(resolucion.tipo);
          final fecha = _fecha(activa, resolucion.tipo);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(estilo.icon, color: estilo.color, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(resolucion.titulo,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ),
                          EstadoBadge(estado: activa.estado),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('FECHA DE RESOLUCIÓN',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(fecha != null ? formatFecha(fecha) : '—'),
                      if (activa.motivoRechazo != null &&
                          activa.motivoRechazo!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('MOTIVO',
                            style: Theme.of(context).textTheme.labelSmall),
                        Text(activa.motivoRechazo!),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Próximo paso: ${resolucion.proximoPaso}'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: null, // R3 pendiente en backend, como el web
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar carta (no disponible aún)'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
