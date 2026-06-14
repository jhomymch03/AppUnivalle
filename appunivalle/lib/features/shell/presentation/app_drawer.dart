// lib/features/shell/presentation/app_drawer.dart
/// Navigation Drawer del estudiante. Replica el sidebar del web
/// (`navigation.ts`): 8 items en el mismo orden. Resalta el item de la ruta
/// actual.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/session_controller.dart';
import '../../configuracion/presentation/server_config_screen.dart';

class _Item {
  const _Item(this.label, this.icon, this.ruta);
  final String label;
  final IconData icon;
  final String ruta;
}

const _items = <_Item>[
  _Item('Dashboard', Icons.home_outlined, '/home'),
  _Item('Nueva Postulación', Icons.edit_document, '/postulacion/nueva'),
  _Item('Mis Postulaciones', Icons.list_alt_outlined, '/mis-postulaciones'),
  _Item('Observaciones', Icons.comment_outlined, '/observaciones'),
  _Item('Documentos', Icons.insert_drive_file_outlined, '/documentos'),
  _Item('Historial', Icons.history, '/historial'),
  _Item('Carta de Respuesta', Icons.mail_outline, '/carta-respuesta'),
  _Item('Perfil', Icons.person_outline, '/perfil'),
];

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessionController>().usuario;
    final actual = GoRouterState.of(context).matchedLocation;
    final nombre =
        '${usuario?.nombres ?? ''} ${usuario?.apellidos ?? ''}'.trim();
    final inicial = (usuario?.nombres.isNotEmpty ?? false)
        ? usuario!.nombres[0].toUpperCase()
        : '?';

    return Drawer(
      backgroundColor: AppColors.fondo,
      child: Column(
        children: [
          _Cabecera(nombre: nombre, email: usuario?.email ?? '', inicial: inicial),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in _items)
                  _MenuTile(
                    icon: item.icon,
                    label: item.label,
                    seleccionado: actual == item.ruta,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (actual != item.ruta) context.go(item.ruta);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borde),
          _MenuTile(
            icon: Icons.dns_outlined,
            label: 'Servidor',
            seleccionado: false,
            onTap: () {
              final deps = context.read<AppDependencies>();
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ServerConfigScreen(dependencies: deps),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            seleccionado: false,
            destructivo: true,
            onTap: () {
              Navigator.of(context).pop();
              context.read<SessionController>().logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Cabecera con degradado carmesi: avatar con inicial, nombre y correo.
class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.email,
    required this.inicial,
  });

  final String nombre;
  final String email;
  final String inicial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (email.isNotEmpty)
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

/// Item del menu con resaltado tipo "pildora" para la ruta activa.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.seleccionado,
    required this.onTap,
    this.destructivo = false,
  });

  final IconData icon;
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;
  final bool destructivo;

  @override
  Widget build(BuildContext context) {
    final colorBase = destructivo ? const Color(0xFFB91C1C) : AppColors.texto;
    final color = seleccionado ? AppColors.primary : colorBase;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: seleccionado ? AppColors.rosaContenedor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight:
                          seleccionado ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
