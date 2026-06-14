/// Pantalla de Configuracion -> Servidor.
///
/// Permite cambiar, sin recompilar, a que backend apunta la app: una IP de
/// red local (`http://192.168.x.x:8000`) o una URL de Cloudflare Tunnel
/// (`https://algo.trycloudflare.com`). El valor se persiste y se aplica en
/// caliente sobre el mismo cliente Dio.
library;

import 'package:flutter/material.dart';

import '../../../core/config/env.dart';
import '../../../core/di/app_dependencies.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.dependencies.serverBaseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.dependencies.setServerBaseUrl(_urlCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servidor actualizado.')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _restablecer() async {
    await widget.dependencies.resetServerBaseUrl();
    if (!mounted) return;
    setState(() => _urlCtrl.text = widget.dependencies.serverBaseUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restablecido al valor por defecto.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servidor')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'URL del backend',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pega la IP de tu PC en la red local o la URL del túnel de '
                    'Cloudflare. No incluyas /api/v1 (se añade solo).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'URL base',
                      hintText: 'http://192.168.0.9:8000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa la URL del servidor';
                      }
                      if (!ApiConfig.looksLikeValidBaseUrl(v)) {
                        return 'Debe empezar por http:// o https:// y tener host';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _guardar(),
                  ),
                  const SizedBox(height: 8),
                  _PreviewEndpoint(controller: _urlCtrl),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _restablecer,
                    child: const Text('Restablecer al valor por defecto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra en vivo el endpoint final que se usara (`<base>/api/v1`).
class _PreviewEndpoint extends StatelessWidget {
  const _PreviewEndpoint({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final base = value.text.trim();
        final preview =
            base.isEmpty ? '—' : ApiConfig.apiBaseUrlFor(base);
        return Text(
          'Se conectará a:  $preview',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        );
      },
    );
  }
}
