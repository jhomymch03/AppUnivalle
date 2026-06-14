// lib/features/postulaciones/data/models/postulacion_form_data.dart
/// Estado mutable del formulario de postulacion + validacion y armado del
/// payload. Espeja `postulacionSchema` y `toCreateInput` del web: la
/// validacion condicional segun `tipoTutor` y la limpieza cruzada de los
/// campos del tutor que no aplica.
library;

import 'tipo_tutor.dart';

class PostulacionFormData {
  PostulacionFormData({
    this.titulo = '',
    this.descripcion = '',
    this.modalidad = '',
    this.tipoTutor = TipoTutor.interno,
    this.tutorDocenteId,
    this.tutorExternoNombres,
    this.tutorExternoApellidos,
    this.tutorExternoCi,
    this.tutorExternoEmail,
    this.tutorExternoTelefono,
    this.tutorExternoCvArchivoId,
    this.tutorExternoTituloArchivoId,
  });

  String titulo;
  String descripcion;
  String modalidad;
  TipoTutor tipoTutor;
  String? tutorDocenteId;
  String? tutorExternoNombres;
  String? tutorExternoApellidos;
  String? tutorExternoCi;
  String? tutorExternoEmail;
  String? tutorExternoTelefono;
  String? tutorExternoCvArchivoId;
  String? tutorExternoTituloArchivoId;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Devuelve un mapa campo->mensaje. Vacio si el formulario es valido.
  Map<String, String> validar() {
    final e = <String, String>{};
    final t = titulo.trim();
    if (t.length < 5) e['titulo'] = 'El titulo debe tener al menos 5 caracteres.';
    if (t.length > 500) e['titulo'] = 'El titulo no puede superar los 500 caracteres.';
    if (descripcion.trim().length < 10) {
      e['descripcion'] = 'La descripcion debe tener al menos 10 caracteres.';
    }
    if (modalidad.trim().length < 3) e['modalidad'] = 'Selecciona una modalidad.';

    if (tipoTutor == TipoTutor.interno) {
      if (tutorDocenteId == null || tutorDocenteId!.isEmpty) {
        e['tutorDocenteId'] = 'Selecciona un tutor de la lista.';
      }
    } else {
      if ((tutorExternoNombres ?? '').trim().length < 2) {
        e['tutorExternoNombres'] = 'Los nombres del tutor externo son obligatorios.';
      }
      if ((tutorExternoApellidos ?? '').trim().length < 2) {
        e['tutorExternoApellidos'] = 'Los apellidos del tutor externo son obligatorios.';
      }
      final email = (tutorExternoEmail ?? '').trim();
      if (email.isNotEmpty && !_emailRe.hasMatch(email)) {
        e['tutorExternoEmail'] = 'Email del tutor invalido.';
      }
    }
    return e;
  }

  /// `true` si no hay errores de validacion.
  bool get esValido => validar().isEmpty;

  String? _limpio(String? v) {
    final s = v?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Cuerpo para POST (crear) y PATCH (editar): igual que el web, envia todos
  /// los campos y pone en `null` los del tutor que no aplica.
  Map<String, dynamic> toJson() {
    final interno = tipoTutor == TipoTutor.interno;
    return {
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'modalidad': modalidad.trim(),
      'tipo_tutor': tipoTutor.wire,
      'tutor_docente_id': interno ? tutorDocenteId : null,
      'tutor_externo_nombres': interno ? null : _limpio(tutorExternoNombres),
      'tutor_externo_apellidos': interno ? null : _limpio(tutorExternoApellidos),
      'tutor_externo_ci': interno ? null : _limpio(tutorExternoCi),
      'tutor_externo_email': interno ? null : _limpio(tutorExternoEmail),
      'tutor_externo_telefono': interno ? null : _limpio(tutorExternoTelefono),
      'tutor_externo_cv_archivo_id': interno ? null : tutorExternoCvArchivoId,
      'tutor_externo_titulo_archivo_id': interno ? null : tutorExternoTituloArchivoId,
    };
  }
}
