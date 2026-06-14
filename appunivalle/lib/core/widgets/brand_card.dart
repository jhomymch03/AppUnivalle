// lib/core/widgets/brand_card.dart
/// Tarjeta blanca redondeada con sombra suave y padding consistente.
/// Envuelve contenido existente; no contiene logica.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final contenido =
        Padding(padding: padding ?? const EdgeInsets.all(16), child: child);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? contenido
          : InkWell(onTap: onTap, child: contenido),
    );
  }
}
