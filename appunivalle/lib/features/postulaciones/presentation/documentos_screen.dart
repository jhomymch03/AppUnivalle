// lib/features/postulaciones/presentation/documentos_screen.dart
/// Pantalla "Documentos": archivos descargables de la postulacion activa.
/// Cada item pide su URL firmada (`GET /archivos/{id}`) y la abre en el visor
/// externo (url_launcher). Espeja `estudiante/Documentos.vue` del web.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../archivos/application/documentos_postulacion.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  late Future<Postulacion?> _carga;
  String? _abriendoId;

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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrir(DocumentoItem doc) async {
    setState(() => _abriendoId = doc.archivoId);
    final repo = context.read<AppDependencies>().archivosRepository;
    try {
      final archivo = await repo.obtener(doc.archivoId);
      final ok = await launchUrl(
        Uri.parse(archivo.url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _snack('No se pudo abrir el documento.');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _abriendoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Documentos'),
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
                      : 'No se pudieron cargar los documentos.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final activa = snapshot.data;
          if (activa == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Todavía no tienes una postulación activa.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/postulacion/nueva'),
                    child: const Text('Ir a Nueva postulación'),
                  ),
                ],
              ),
            );
          }
          final docs = documentosDePostulacion(activa);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(activa.titulo,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  EstadoBadge(estado: activa.estado),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No hay documentos en tu expediente todavía.'),
                  ),
                )
              else
                for (final doc in docs)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(doc.label),
                      trailing: _abriendoId == doc.archivoId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new),
                      onTap:
                          _abriendoId == null ? () => _abrir(doc) : null,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
