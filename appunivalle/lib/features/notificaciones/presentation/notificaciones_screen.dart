// lib/features/notificaciones/presentation/notificaciones_screen.dart
/// Pantalla de notificaciones del estudiante: lista (icono por tipo, titulo,
/// mensaje, fecha relativa, punto si no leida), marcar todas, pull-to-refresh.
/// Tocar una la marca leida y navega a la postulacion del estudiante.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/brand_card.dart';
import '../application/notificaciones_controller.dart';
import '../application/tipo_notificacion.dart';
import '../data/models/notificacion.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificacionesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (ctrl.noLeidas > 0)
            TextButton.icon(
              onPressed: () => context
                  .read<NotificacionesController>()
                  .marcarTodasLeidas(),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Marcar todas'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificacionesController>().refrescar(),
        child: _cuerpo(context, ctrl),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, NotificacionesController ctrl) {
    if (ctrl.cargando && ctrl.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ctrl.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.notifications_none_outlined,
                    size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  ctrl.error ?? 'No tienes notificaciones todavía.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.items.length,
      itemBuilder: (context, i) => _tile(context, ctrl.items[i]),
    );
  }

  Widget _tile(BuildContext context, Notificacion n) {
    final estilo = estiloNotificacion(n.tipo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BrandCard(
        padding: const EdgeInsets.all(14),
        onTap: () => _abrir(context, n),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono por tipo, en cuadrito tintado de su color.
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: estilo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(estilo.icon, color: estilo.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: n.leida ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.mensaje,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fechaRelativa(n.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            // Punto de "no leida".
            if (!n.leida)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrir(BuildContext context, Notificacion n) async {
    final ctrl = context.read<NotificacionesController>();
    if (!n.leida) {
      try {
        await ctrl.marcarLeida(n.id);
      } on Object {
        // silencioso: no bloquea la navegación
      }
    }
    if (!context.mounted) return;
    if (n.postulacionId != null) {
      context.push('/postulacion/nueva');
    }
  }
}
