// lib/core/widgets/form_section.dart
/// Seccion de formulario al estilo movil: encabezado (icono + titulo) sobre una
/// tarjeta blanca que agrupa los campos con un ritmo de espaciado uniforme.
/// Centraliza la separacion entre campos para que sea pareja en toda la app.
library;

import 'package:flutter/material.dart';

import 'brand_card.dart';
import 'section_header.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.icon,
    required this.titulo,
    required this.children,
    this.gap = 16,
  });

  final IconData icon;
  final String titulo;
  final List<Widget> children;

  /// Separacion vertical entre cada campo dentro de la tarjeta.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: icon, titulo: titulo),
        const SizedBox(height: 12),
        BrandCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _conEspaciado(),
          ),
        ),
      ],
    );
  }

  List<Widget> _conEspaciado() {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i != children.length - 1) out.add(SizedBox(height: gap));
    }
    return out;
  }
}
