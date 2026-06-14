// lib/features/catalogos/data/modalidades_repository.dart
/// Repositorio de modalidades. Fuente de verdad: `GET /modalidades?activa=true`
/// (se envia el `nombre` al crear la postulacion). Si la llamada falla o no
/// devuelve nada, cae al listado fijo del web ([kModalidadesFallback]).
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';

/// Listado fijo del web (deuda tecnica del frontend), usado como respaldo.
const List<String> kModalidadesFallback = [
  'Proyecto de grado',
  'Tesis',
  'Trabajo dirigido',
];

/// Extrae los nombres de la respuesta; si viene vacia, usa el fallback.
List<String> modalidadesDesdeJson(List<dynamic> data) {
  final nombres = data
      .whereType<Map<String, dynamic>>()
      .map((m) => m['nombre'] as String?)
      .whereType<String>()
      .toList();
  return nombres.isEmpty ? kModalidadesFallback : nombres;
}

class ModalidadesRepository {
  ModalidadesRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Nombres de las modalidades activas; fallback ante error o lista vacia.
  Future<List<String>> listar() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/modalidades',
        queryParameters: {'activa': true},
      );
      return modalidadesDesdeJson(response.data ?? const []);
    } on DioException catch (_) {
      return kModalidadesFallback;
    } on ApiException catch (_) {
      return kModalidadesFallback;
    }
  }
}
