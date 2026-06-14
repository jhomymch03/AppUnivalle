// lib/features/archivos/application/documentos_postulacion.dart
/// Devuelve los documentos descargables presentes en una postulacion, con su
/// etiqueta para mostrar. Espeja `DocumentosExpediente.vue` del web: carta de
/// postulacion (si existe) y, para tutor externo, su CV y titulo.
library;

import '../../postulaciones/data/models/postulacion.dart';

/// Un documento descargable: etiqueta + id de archivo (para pedir la URL).
typedef DocumentoItem = ({String label, String archivoId});

List<DocumentoItem> documentosDePostulacion(Postulacion p) {
  final docs = <DocumentoItem>[];
  if (p.cartaPostulacionArchivoId != null) {
    docs.add((label: 'Carta de postulación', archivoId: p.cartaPostulacionArchivoId!));
  }
  if (p.tutorExternoCvArchivoId != null) {
    docs.add((label: 'CV del tutor', archivoId: p.tutorExternoCvArchivoId!));
  }
  if (p.tutorExternoTituloArchivoId != null) {
    docs.add((label: 'Título académico del tutor', archivoId: p.tutorExternoTituloArchivoId!));
  }
  return docs;
}
