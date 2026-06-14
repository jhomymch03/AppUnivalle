// lib/core/widgets/hero_header.dart
/// Cabecera "hero" con degradado carmesi, titulo/subtitulo en blanco y una
/// pildora opcional. Recibe su contenido; no inventa datos.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.pildora,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? pildora;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitulo!,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
          if (pildora != null) ...[const SizedBox(height: 12), pildora!],
        ],
      ),
    );
  }
}
