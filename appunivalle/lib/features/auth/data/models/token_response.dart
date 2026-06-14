/// Respuesta de `POST /api/v1/auth/login`.
///
/// Espeja `TokenOutput` del backend:
///   { "access_token": "...", "token_type": "bearer", "expira_en": 3600 }
///
/// El backend solo emite access token (no hay refresh): cuando `expira_en`
/// se cumple, el siguiente request recibira 401 y la app pedira re-login.
library;

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiraEn,
  });

  final String accessToken;
  final String tokenType;

  /// Segundos hasta que el token expira (desde su emision).
  final int expiraEn;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      expiraEn: (json['expira_en'] as num).toInt(),
    );
  }
}
