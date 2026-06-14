/// Home del estudiante (Fase B).
///
/// Saludo + resumen de la postulacion mas reciente (estado + stepper) y acceso
/// a "Mis postulaciones". Si no tiene ninguna, muestra un estado vacio.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/hero_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/application/session_controller.dart';
import '../../postulaciones/application/postulacion_actual.dart';
import '../../postulaciones/data/models/postulacion.dart';
import '../../postulaciones/presentation/widgets/estado_badge.dart';
import '../../postulaciones/presentation/widgets/stepper_proceso.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';

class HomeEstudianteScreen extends StatefulWidget {
  const HomeEstudianteScreen({super.key});

  @override
  State<HomeEstudianteScreen> createState() => _HomeEstudianteScreenState();
}

class _HomeEstudianteScreenState extends State<HomeEstudianteScreen> {
  late Future<List<Postulacion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Postulacion>> _cargar() =>
      context.read<AppDependencies>().postulacionesRepository.listarMias();

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessionController>().usuario;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: const [NotificationsBell()],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            HeroHeader(
              titulo: 'Hola, ${usuario?.nombres ?? ''} 👋',
              subtitulo: usuario?.email,
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Postulacion>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(
                    mensaje: snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'No se pudo cargar tu información.',
                    onReintentar: _refrescar,
                  );
                }

                final lista = snapshot.data ?? const [];
                final destacada = pickResumenHome(lista);

                if (destacada == null) {
                  return const _SinPostulaciones();
                }

                return _ResumenActual(
                  postulacion: destacada,
                  total: lista.length,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenActual extends StatelessWidget {
  const _ResumenActual({required this.postulacion, required this.total});

  final Postulacion postulacion;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = postulacion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          icon: Icons.assignment_outlined,
          titulo: 'Tu postulación más reciente',
        ),
        const SizedBox(height: 12),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.codigoCorto,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.titulo,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  EstadoBadge(estado: p.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Actualizada el ${formatFecha(p.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StepperProceso(estado: p.estado),
        const SizedBox(height: 16),
        if (esEditable(p.estado)) ...[
          PrimaryButton(
            label: 'Editar / Enviar',
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/postulacion/nueva'),
          ),
          const SizedBox(height: 8),
        ],
        SecondaryButton(
          label: total > 1
              ? 'Ver mis postulaciones ($total)'
              : 'Ver mis postulaciones',
          icon: Icons.folder_shared_outlined,
          onPressed: () => context.push('/mis-postulaciones'),
        ),
      ],
    );
  }
}

class _SinPostulaciones extends StatelessWidget {
  const _SinPostulaciones();

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined,
              size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text(
            'Aún no tienes una postulación',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando crees tu propuesta de tema y tutor, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Crear postulación',
            icon: Icons.add,
            onPressed: () => context.push('/postulacion/nueva'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Reintentar',
            onPressed: onReintentar,
          ),
        ],
      ),
    );
  }
}
