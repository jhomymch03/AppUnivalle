// lib/features/catalogos/data/models/carrera.dart
/// Carrera — espeja `CarreraOutput` (solo los campos que la app muestra).
library;

class Carrera {
  const Carrera({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.facultad,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String? facultad;

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      facultad: json['facultad'] as String?,
    );
  }
}
