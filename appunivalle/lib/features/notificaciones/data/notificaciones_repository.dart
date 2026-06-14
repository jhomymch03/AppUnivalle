// lib/features/notificaciones/data/notificaciones_repository.dart
/// Repositorio de notificaciones in-app. Consume los endpoints del backend
/// (no se inventa ninguno) y traduce errores Dio a [ApiException].
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/notificacion.dart';

class NotificacionesRepository {
  NotificacionesRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Lista mis notificaciones (`GET /notificaciones/mis`), más recientes primero.
  Future<List<Notificacion>> listarMias({bool soloNoLeidas = false, int? limit}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/notificaciones/mis',
        queryParameters: {
          if (soloNoLeidas) 'solo_no_leidas': true,
          if (limit != null) 'limit': limit, // ignore: use_null_aware_elements
        },
      );
      final data = response.data ?? const [];
      return data
          .map((e) => Notificacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cantidad de no leídas (`GET /notificaciones/contar-no-leidas`).
  Future<int> contarNoLeidas() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/notificaciones/contar-no-leidas');
      return (response.data?['no_leidas'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Marca una como leída (`PATCH /notificaciones/{id}/leer`).
  Future<void> marcarLeida(String id) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/notificaciones/$id/leer');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Marca todas como leídas (`POST /notificaciones/marcar-todas-leidas`).
  Future<int> marcarTodasLeidas() async {
    try {
      final response = await _dio
          .post<Map<String, dynamic>>('/notificaciones/marcar-todas-leidas');
      return (response.data?['no_leidas'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
