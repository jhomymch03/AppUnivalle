/// Utilidades de formato compartidas (fechas y etiquetas de rol).
library;

/// Formatea una fecha como `dd/MM/yyyy` (en hora local).
String formatFecha(DateTime fecha) {
  final f = fecha.toLocal();
  final dd = f.day.toString().padLeft(2, '0');
  final mm = f.month.toString().padLeft(2, '0');
  return '$dd/$mm/${f.year}';
}

/// Devuelve una descripcion relativa simple ("hace 3 d", "hace 2 h").
String fechaRelativa(DateTime fecha) {
  final d = DateTime.now().difference(fecha.toLocal());
  if (d.inSeconds < 60) return 'hace instantes';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays < 30) return 'hace ${d.inDays} d';
  final meses = (d.inDays / 30).floor();
  if (meses < 12) return 'hace $meses mes(es)';
  return 'hace ${(d.inDays / 365).floor()} año(s)';
}

/// Etiqueta legible para un rol del backend (string libre).
String etiquetaRol(String? rol) {
  switch (rol) {
    case 'estudiante':
      return 'Estudiante';
    case 'secretaria':
      return 'Secretaría';
    case 'director':
      return 'Director';
    case 'cat':
      return 'CAT';
    case 'vicerrector':
      return 'Vicerrector';
    case 'admin':
      return 'Admin';
    case null:
      return 'Sistema';
    default:
      return rol;
  }
}
