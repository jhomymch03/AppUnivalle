/// Postulacion del estudiante — espeja `PostulacionOutput` (campos que usa la
/// app; el backend devuelve mas, pero solo mapeamos lo que mostramos).
library;

import 'estado_postulacion.dart';
import 'tipo_tutor.dart';

class Postulacion {
  const Postulacion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.modalidad,
    required this.tipoTutor,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    this.codigo,
    this.justificacion,
    this.tutorDocenteId,
    this.tutorExternoNombres,
    this.tutorExternoApellidos,
    this.tutorExternoCi,
    this.tutorExternoEmail,
    this.tutorExternoTelefono,
    this.cartaPostulacionArchivoId,
    this.tutorExternoCvArchivoId,
    this.tutorExternoTituloArchivoId,
    this.motivoRechazo,
    this.carreraId,
    this.fechaAprobacionFinal,
    this.fechaRechazo,
  });

  final String id;
  final String? codigo;
  final String titulo;
  final String descripcion;
  final String? justificacion;
  final String modalidad;
  final TipoTutor tipoTutor;
  final EstadoPostulacion estado;

  final String? tutorDocenteId;
  final String? tutorExternoNombres;
  final String? tutorExternoApellidos;
  final String? tutorExternoCi;
  final String? tutorExternoEmail;
  final String? tutorExternoTelefono;

  final String? cartaPostulacionArchivoId;
  final String? tutorExternoCvArchivoId;
  final String? tutorExternoTituloArchivoId;

  final String? motivoRechazo;

  final String? carreraId;
  final DateTime? fechaAprobacionFinal;
  final DateTime? fechaRechazo;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Identificador legible: usa `codigo` del backend o, si aun es null, un
  /// fragmento del UUID (mismo criterio que el frontend web).
  String get codigoCorto =>
      codigo ?? '#${id.substring(0, 8).toUpperCase()}';

  /// Nombre completo del tutor externo (vacio si no aplica).
  String get tutorExternoNombreCompleto =>
      '${tutorExternoNombres ?? ''} ${tutorExternoApellidos ?? ''}'.trim();

  factory Postulacion.fromJson(Map<String, dynamic> json) {
    return Postulacion(
      id: json['id'] as String,
      codigo: json['codigo'] as String?,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      justificacion: json['justificacion'] as String?,
      modalidad: json['modalidad'] as String,
      tipoTutor: TipoTutor.fromWire(json['tipo_tutor'] as String),
      estado: EstadoPostulacion.fromWire(json['estado_actual'] as String),
      tutorDocenteId: json['tutor_docente_id'] as String?,
      tutorExternoNombres: json['tutor_externo_nombres'] as String?,
      tutorExternoApellidos: json['tutor_externo_apellidos'] as String?,
      tutorExternoCi: json['tutor_externo_ci'] as String?,
      tutorExternoEmail: json['tutor_externo_email'] as String?,
      tutorExternoTelefono: json['tutor_externo_telefono'] as String?,
      cartaPostulacionArchivoId: json['carta_postulacion_archivo_id'] as String?,
      tutorExternoCvArchivoId: json['tutor_externo_cv_archivo_id'] as String?,
      tutorExternoTituloArchivoId:
          json['tutor_externo_titulo_archivo_id'] as String?,
      motivoRechazo: json['motivo_rechazo'] as String?,
      carreraId: json['carrera_id'] as String?,
      fechaAprobacionFinal: (json['fecha_aprobacion_final'] as String?) != null
          ? DateTime.parse(json['fecha_aprobacion_final'] as String)
          : null,
      fechaRechazo: (json['fecha_rechazo'] as String?) != null
          ? DateTime.parse(json['fecha_rechazo'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
