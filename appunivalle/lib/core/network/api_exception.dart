/// Excepcion tipada de la capa de red.
///
/// Traduce cualquier fallo de Dio (timeout, sin conexion, o una respuesta de
/// error del backend) a un objeto uniforme con `statusCode` + `message`
/// legible. Normaliza el envelope de FastAPI:
///   - HTTPException:  `{ "detail": "texto" }`
///   - Validacion 422: `{ "detail": [ { "loc": [...], "msg": "...", ... } ] }`
///
/// Asi la capa de UI/repositorios nunca manipula `DioException` crudo: solo
/// captura [ApiException] y muestra `.message`.
library;

import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  /// Codigo HTTP (0 si nunca hubo respuesta: timeout, sin red, DNS).
  final int statusCode;

  /// Mensaje legible para mostrar al usuario.
  final String message;

  /// `true` si el token fue rechazado (sesion expirada o invalida).
  bool get isUnauthorized => statusCode == 401;

  /// Construye una [ApiException] a partir de un [DioException].
  factory ApiException.fromDio(DioException error) {
    // Fallos sin respuesta HTTP (red/timeout).
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          statusCode: 0,
          message: 'La conexion tardo demasiado. Revisa tu red e intenta de nuevo.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          statusCode: 0,
          message: 'No se pudo conectar al servidor. Verifica la URL y tu red.',
        );
      case DioExceptionType.cancel:
        return const ApiException(statusCode: 0, message: 'Solicitud cancelada.');
      case DioExceptionType.badCertificate:
        return const ApiException(
          statusCode: 0,
          message: 'Certificado del servidor no valido.',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break; // se procesa abajo con la respuesta del backend
    }

    final response = error.response;
    final status = response?.statusCode ?? 0;
    final message = _extractDetail(response?.data) ?? _defaultMessage(status);
    return ApiException(statusCode: status, message: message);
  }

  /// Extrae el mensaje del envelope `{detail}` del backend (string o lista 422).
  static String? _extractDetail(dynamic data) {
    if (data is! Map || !data.containsKey('detail')) return null;
    final detail = data['detail'];

    // Caso HTTPException: { "detail": "texto" }
    if (detail is String) return detail;

    // Caso validacion 422: { "detail": [ { "msg": "...", ... } ] }
    if (detail is List) {
      final mensajes = detail
          .whereType<Map>()
          .map((item) => item['msg'])
          .whereType<String>()
          .toList();
      if (mensajes.isNotEmpty) return mensajes.join('. ');
    }
    return null;
  }

  /// Mensajes genericos por status cuando el backend no envia `detail`.
  static String _defaultMessage(int status) {
    return switch (status) {
      400 => 'Solicitud invalida.',
      401 => 'Credenciales invalidas o sesion expirada.',
      403 => 'No tienes permiso para realizar esta accion.',
      404 => 'El recurso solicitado no existe.',
      409 => 'La operacion entra en conflicto con el estado actual.',
      422 => 'Datos invalidos.',
      _ when status >= 500 => 'Error del servidor. Intenta de nuevo en un momento.',
      _ => 'Ocurrio un error inesperado.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
