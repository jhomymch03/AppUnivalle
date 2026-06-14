// lib/features/catalogos/data/carreras_repository.dart
/// Repositorio de carreras. Solo lectura del detalle (`GET /carreras/{id}`),
/// que cualquier autenticado puede consultar. Lo usa Perfil para mostrar la
/// carrera derivada de la postulacion activa del estudiante.
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/carrera.dart';

class CarrerasRepository {
  CarrerasRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Carrera> obtener(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/carreras/$id');
      return Carrera.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
