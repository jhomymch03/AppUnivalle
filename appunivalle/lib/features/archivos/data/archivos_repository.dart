// lib/features/archivos/data/archivos_repository.dart
/// Repositorio de archivos. Sube PDFs al backend (`POST /archivos`,
/// multipart/form-data, campo `file`). El backend solo acepta
/// `application/pdf` y un maximo de 10 MB; los errores (422) llegan como
/// [ApiException] con el `detail` del backend.
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/archivo_subido.dart';

class ArchivosRepository {
  ArchivosRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Sube un PDF y devuelve su metadata (id + url firmada).
  Future<ArchivoSubido> subir({
    required List<int> bytes,
    required String nombre,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: nombre,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });
      final response =
          await _dio.post<Map<String, dynamic>>('/archivos', data: form);
      return ArchivoSubido.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Metadata + URL firmada de un archivo (`GET /archivos/{id}`).
  Future<ArchivoSubido> obtener(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/archivos/$id');
      return ArchivoSubido.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
