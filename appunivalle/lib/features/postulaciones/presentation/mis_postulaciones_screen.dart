/// Pantalla "Mis Postulaciones" (Fase B, solo lectura).
///
/// Lista las postulaciones del estudiante (`GET /postulaciones/mis`) en
/// tarjetas, con filtro por estado mediante chips. Tap -> detalle.
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
import '../data/models/estado_postulacion.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({super.key});

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> {
  late Future<List<Postulacion>> _future;
  EstadoPostulacion? _filtro;

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
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Mis Postulaciones'),
        actions: const [NotificationsBell()],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<Postulacion>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                mensaje: snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'No se pudieron cargar las postulaciones.',
                onReintentar: _refrescar,
              );
            }

            final todas = snapshot.data ?? const [];
            final estadosPresentes =
                todas.map((p) => p.estado).toSet().toList()
                  ..sort((a, b) => a.index.compareTo(b.index));
            final filtradas = _filtro == null
                ? todas
                : todas.where((p) => p.estado == _filtro).toList();

            if (todas.isEmpty) {
              return const _Vacio(
                texto: 'Todavía no tienes ninguna postulación.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                HeroHeader(
                  titulo: 'Mis Postulaciones',
                  subtitulo: todas.length == 1
                      ? '1 postulación en total'
                      : '${todas.length} postulaciones en total',
                ),
                const SizedBox(height: 20),
                if (estadosPresentes.length > 1)
                  _FiltroChips(
                    estados: estadosPresentes,
                    seleccionado: _filtro,
                    onSelect: (e) => setState(() => _filtro = e),
                  ),
                if (filtradas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: _Vacio(texto: 'Ninguna coincide con el filtro.'),
                  )
                else
                  for (final p in filtradas) _PostulacionCard(postulacion: p),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FiltroChips extends StatelessWidget {
  const _FiltroChips({
    required this.estados,
    required this.seleccionado,
    required this.onSelect,
  });

  final List<EstadoPostulacion> estados;
  final EstadoPostulacion? seleccionado;
  final ValueChanged<EstadoPostulacion?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: seleccionado == null,
            onSelected: (_) => onSelect(null),
          ),
          for (final e in estados)
            ChoiceChip(
              label: Text(e.label),
              selected: seleccionado == e,
              onSelected: (_) => onSelect(e),
            ),
        ],
      ),
    );
  }
}

class _PostulacionCard extends StatelessWidget {
  const _PostulacionCard({required this.postulacion});

  final Postulacion postulacion;

  @override
  Widget build(BuildContext context) {
    final p = postulacion;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/postulacion/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borde),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _Meta(
                      icono: Icons.category_outlined,
                      label: 'Modalidad',
                      valor: p.modalidad),
                  _Meta(
                      icono: Icons.person_outline,
                      label: 'Tutor',
                      valor: p.tipoTutor.label),
                  _Meta(
                      icono: Icons.event_outlined,
                      label: 'Creada',
                      valor: formatFecha(p.createdAt)),
                  _Meta(
                      icono: Icons.update_outlined,
                      label: 'Actualizada',
                      valor: formatFecha(p.updatedAt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icono,
    required this.label,
    required this.valor,
  });

  final IconData icono;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: AppColors.primary),
        const SizedBox(width: 5),
        RichText(
          text: TextSpan(
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: outline),
            children: [
              TextSpan(text: '$label: '),
              TextSpan(
                text: valor,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.texto),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(mensaje, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
