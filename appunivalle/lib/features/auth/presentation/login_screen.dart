/// Pantalla de login real (Fase A).
///
/// Delega toda la logica al [SessionController] (Provider): el guard de rol,
/// el guardado del token y la navegacion los maneja la sesion + el router.
/// Mantiene el acceso a la configuracion de servidor (LAN / Cloudflare).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_card.dart';
import '../../configuracion/presentation/server_config_screen.dart';
import '../application/session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  /// Controla el "ojito": si la contraseña se muestra u oculta.
  bool _verPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<SessionController>().login(
          _emailCtrl.text,
          _passwordCtrl.text,
        );
  }

  Future<void> _abrirConfigServidor() async {
    final deps = context.read<AppDependencies>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerConfigScreen(dependencies: deps),
      ),
    );
    if (mounted) setState(() {}); // refresca el pie con la URL
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final cargando = session.status == SessionStatus.autenticando;
    final deps = context.read<AppDependencies>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            tooltip: 'Servidor',
            icon: const Icon(Icons.dns_outlined),
            onPressed: _abrirConfigServidor,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginHeader(),
                  const SizedBox(height: 28),
                  BrandCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          enabled: !cargando,
                          decoration: const InputDecoration(
                            labelText: 'Correo institucional',
                            hintText: 'usuario@est.univalle.edu',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa tu correo'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: !_verPassword,
                          autofillHints: const [AutofillHints.password],
                          enabled: !cargando,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _verPassword
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                              icon: Icon(
                                _verPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: cargando
                                  ? null
                                  : () => setState(
                                      () => _verPassword = !_verPassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingresa tu contraseña'
                              : null,
                          onFieldSubmitted: (_) => _ingresar(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: cargando ? null : _ingresar,
                          child: cargando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Ingresar'),
                        ),
                        if (session.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _ErrorMensaje(mensaje: session.errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ServidorFooter(
        url: deps.serverBaseUrl,
        onTap: _abrirConfigServidor,
      ),
    );
  }
}

/// Cabecera de la pantalla: insignia carmesi con el icono + textos de bienvenida.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: const Icon(Icons.school_outlined, size: 38, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bienvenido',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Sistema de Titulaciones — UniValle',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

/// Mensaje de error del login, dentro de un contenedor rosado suave.
class _ErrorMensaje extends StatelessWidget {
  const _ErrorMensaje({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rosaContenedor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: error, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie que muestra a que servidor apunta la app; toca para cambiarlo.
class _ServidorFooter extends StatelessWidget {
  const _ServidorFooter({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.dns_outlined, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Servidor: $url',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
