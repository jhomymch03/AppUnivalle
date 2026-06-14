/// Seccion de documentos del expediente — Fase B: solo indica cuales existen
/// (presentes / faltantes). La descarga/visualizacion llega en la Fase C.
library;

import 'package:flutter/material.dart';

import '../../data/models/postulacion.dart';
import '../../data/models/tipo_tutor.dart';

class DocumentosSeccion extends StatelessWidget {
  const DocumentosSeccion({super.key, required this.postulacion});

  final Postulacion postulacion;

  @override
  Widget build(BuildContext context) {
    final docs = <({String nombre, bool presente})>[
      (
        nombre: 'Carta de postulación',
        presente: postulacion.cartaPostulacionArchivoId != null,
      ),
      if (postulacion.tipoTutor == TipoTutor.externo) ...[
        (
          nombre: 'CV del tutor externo',
          presente: postulacion.tutorExternoCvArchivoId != null,
        ),
        (
          nombre: 'Título del tutor externo',
          presente: postulacion.tutorExternoTituloArchivoId != null,
        ),
      ],
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final d in docs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  d.presente
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: d.presente
                      ? const Color(0xFF059669)
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(d.nombre),
                subtitle: Text(d.presente ? 'Adjuntado' : 'Pendiente'),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'La descarga de archivos estará disponible próximamente.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
