/// Repositorio de postulaciones (solo lectura en la Fase B).
///
/// Consume los endpoints del estudiante y traduce errores Dio a
/// [ApiException]. Endpoints reales usados (no se inventa ninguno):
///   - GET /postulaciones/mis       -> [listarMias]
///   - GET /postulaciones/{id}      -> [obtenerDetalle]
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/postulacion.dart';
import 'models/postulacion_detalle.dart';

class PostulacionesRepository {
  PostulacionesRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Lista las postulaciones del estudiante autenticado (`GET /postulaciones/mis`).
  Future<List<Postulacion>> listarMias() async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/postulaciones/mis');
      final data = response.data ?? const [];
      return data
          .map((e) => Postulacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Detalle de una postulacion propia (`GET /postulaciones/{id}`),
  /// con historial y observaciones embebidos.
  Future<PostulacionDetalle> obtenerDetalle(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/postulaciones/$id');
      return PostulacionDetalle.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Crea una postulacion en BORRADOR (`POST /postulaciones`).
  Future<Postulacion> crear(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('/postulaciones', data: body);
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Edita una postulacion en estado editable (`PATCH /postulaciones/{id}`).
  Future<Postulacion> editar(String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/postulaciones/$id',
        data: body,
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Envia (o reenvia) a secretaria (`POST /postulaciones/{id}/enviar-a-secretaria`).
  Future<Postulacion> enviarASecretaria(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/postulaciones/$id/enviar-a-secretaria',
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
