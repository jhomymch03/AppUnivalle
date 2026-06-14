/// Pantalla mostrada cuando inicia sesion alguien que NO es estudiante.
///
/// Esta app movil es solo para estudiantes; el resto de roles usan la version
/// web. La sesion ya fue cerrada por el [SessionController]; aqui solo se
/// informa y se ofrece volver al login.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/session_controller.dart';

class AccesoDenegadoScreen extends StatelessWidget {
  const AccesoDenegadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Acceso restringido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta aplicación es solo para estudiantes. Si eres personal '
                'administrativo o docente, ingresa desde la versión web.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    context.read<SessionController>().volverALogin(),
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
