// lib/features/perfil/presentation/perfil_screen.dart
/// Pantalla "Perfil / Mi cuenta": datos de /auth/me, carrera derivada de la
/// postulacion activa, y acciones self-service (editar datos via PATCH /auth/me,
/// cambiar contraseña via POST /auth/cambiar-password). Espeja
/// `estudiante/Perfil.vue` + `PerfilSelfService.vue` del web.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/application/session_controller.dart';
import '../../catalogos/data/models/carrera.dart';
import '../../notificaciones/presentation/notifications_bell.dart';
import '../../shell/presentation/app_drawer.dart';
import '../../postulaciones/application/postulacion_actual.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<Carrera?> _carrera;

  /// Toggles del "ojito" para el dialogo de cambiar contraseña.
  bool _verPassActual = false;
  bool _verPassNueva = false;

  @override
  void initState() {
    super.initState();
    _carrera = _cargarCarrera();
  }

  Future<Carrera?> _cargarCarrera() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    final activa = pickActiva(lista);
    final id = activa?.carreraId;
    if (id == null) return null;
    return deps.carrerasRepository.obtener(id);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessionController>().usuario;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        actions: const [NotificationsBell()],
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _PerfilHero(
                  inicial:
                      usuario.nombres.isNotEmpty ? usuario.nombres[0] : '?',
                  nombre: usuario.nombreCompleto,
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  icon: Icons.person_outline,
                  titulo: 'Datos personales',
                ),
                const SizedBox(height: 12),
                BrandCard(
                  child: _FilaDato(
                    icono: Icons.alternate_email,
                    label: 'Correo',
                    valor: usuario.email,
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  icon: Icons.school_outlined,
                  titulo: 'Información académica',
                ),
                const SizedBox(height: 12),
                FutureBuilder<Carrera?>(
                  future: _carrera,
                  builder: (context, snapshot) {
                    final c = snapshot.data;
                    if (c == null) {
                      return const BrandCard(
                        child: _AcademicaVacia(),
                      );
                    }
                    return BrandCard(
                      child: Column(
                        children: [
                          _FilaDato(
                            icono: Icons.account_balance_outlined,
                            label: 'Carrera',
                            valor: '${c.nombre} (${c.codigo})',
                          ),
                          if (c.facultad != null) ...[
                            const Divider(height: 24, color: AppColors.borde),
                            _FilaDato(
                              icono: Icons.apartment_outlined,
                              label: 'Facultad',
                              valor: c.facultad!,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => _editarDatos(usuario.nombres,
                      usuario.apellidos, usuario.telefono),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar datos'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _cambiarPassword,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Cambiar contraseña'),
                ),
              ],
            ),
    );
  }

  Future<void> _editarDatos(
      String nombres, String apellidos, String? telefono) async {
    final nombresCtl = TextEditingController(text: nombres);
    final apellidosCtl = TextEditingController(text: apellidos);
    final telefonoCtl = TextEditingController(text: telefono ?? '');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar datos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombresCtl,
                decoration: const InputDecoration(labelText: 'Nombres'),
              ),
              TextField(
                controller: apellidosCtl,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              TextField(
                controller: telefonoCtl,
                decoration:
                    const InputDecoration(labelText: 'Teléfono (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );

    if (guardar != true) return;
    if (nombresCtl.text.trim().length < 2 ||
        apellidosCtl.text.trim().length < 2) {
      _snack('Nombres y apellidos deben tener al menos 2 caracteres.');
      return;
    }

    if (!mounted) return;
    final deps = context.read<AppDependencies>();
    final session = context.read<SessionController>();
    try {
      final actualizado = await deps.authRepository.actualizarPerfil(
        nombres: nombresCtl.text.trim(),
        apellidos: apellidosCtl.text.trim(),
        telefono: telefonoCtl.text.trim().isEmpty
            ? null
            : telefonoCtl.text.trim(),
      );
      session.actualizarUsuarioLocal(actualizado);
      _snack('Perfil actualizado.');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _cambiarPassword() async {
    final actualCtl = TextEditingController();
    final nuevaCtl = TextEditingController();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Cambiar contraseña'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: actualCtl,
                    obscureText: !_verPassActual,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      suffixIcon: _OjitoBoton(
                        visible: _verPassActual,
                        onPressed: () =>
                            setLocal(() => _verPassActual = !_verPassActual),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nuevaCtl,
                    obscureText: !_verPassNueva,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña (mín. 6)',
                      suffixIcon: _OjitoBoton(
                        visible: _verPassNueva,
                        onPressed: () =>
                            setLocal(() => _verPassNueva = !_verPassNueva),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Cambiar')),
            ],
          );
        },
      ),
    );
    // Reinicia los toggles para el proximo uso del dialogo.
    _verPassActual = false;
    _verPassNueva = false;

    if (guardar != true) return;
    if (nuevaCtl.text.length < 6) {
      _snack('La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (!mounted) return;
    final deps = context.read<AppDependencies>();
    try {
      await deps.authRepository.cambiarPassword(
        passwordActual: actualCtl.text,
        passwordNueva: nuevaCtl.text,
      );
      _snack('Contraseña cambiada.');
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }
}

/// Cabecera con degradado carmesi: avatar con la inicial, nombre y pildora "Estudiante".
class _PerfilHero extends StatelessWidget {
  const _PerfilHero({required this.inicial, required this.nombre});

  final String inicial;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Text(
              inicial.toUpperCase(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Estudiante',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de dato: icono + etiqueta (arriba) + valor (abajo).
class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.icono,
    required this.label,
    required this.valor,
  });

  final IconData icono;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Estado vacio de la seccion academica (aun sin postulacion).
class _AcademicaVacia extends StatelessWidget {
  const _AcademicaVacia();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline,
            size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'No disponible hasta tener una postulación.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ],
    );
  }
}

/// Boton "ojito" reutilizable para mostrar/ocultar contraseñas en los dialogos.
class _OjitoBoton extends StatelessWidget {
  const _OjitoBoton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: onPressed,
    );
  }
}
