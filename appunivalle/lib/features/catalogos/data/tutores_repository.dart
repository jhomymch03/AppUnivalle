// lib/features/catalogos/data/tutores_repository.dart
/// Repositorio de catalogo de tutores internos. Trae los habilitados y los
/// docentes y los cruza (igual que el web) en una lista lista para el selector.
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'models/tutor_option.dart';

class TutoresRepository {
  TutoresRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Lista las opciones de tutor interno (habilitados ⨝ docentes).
  Future<List<TutorOption>> listarOpcionesTutor() async {
    try {
      final habilitadosRes =
          await _dio.get<List<dynamic>>('/tutores-habilitados');
      final docentesRes = await _dio.get<List<dynamic>>('/docentes');
      final habilitados = (habilitadosRes.data ?? const [])
          .cast<Map<String, dynamic>>();
      final docentes =
          (docentesRes.data ?? const []).cast<Map<String, dynamic>>();
      return construirOpcionesTutor(habilitados, docentes);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
