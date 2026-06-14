/// Payload de `POST /api/v1/auth/login`.
///
/// Espeja `LoginInput` del backend. El backend valida que el email sea de un
/// dominio institucional (`@univalle.edu` / `@est.univalle.edu`).
library;

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}
