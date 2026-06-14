// lib/features/archivos/data/models/archivo_subido.dart
/// Respuesta de `POST /archivos` (espeja `ArchivoConUrlOutput`): solo los
/// campos que la app necesita.
library;

class ArchivoSubido {
  const ArchivoSubido({
    required this.id,
    required this.nombre,
    required this.url,
  });

  final String id;
  final String nombre;
  final String url;

  factory ArchivoSubido.fromJson(Map<String, dynamic> json) {
    return ArchivoSubido(
      id: json['id'] as String,
      nombre: json['nombre_original'] as String,
      url: json['url'] as String,
    );
  }
}
