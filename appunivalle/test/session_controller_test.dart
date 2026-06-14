// Tests del SessionController: guard de rol y flujos de sesion.
//
// Usa un AuthRepository falso (sin red ni storage real) para verificar la
// logica de negocio: solo estudiantes entran; otros roles quedan bloqueados.

import 'package:flutter_test/flutter_test.dart';

import 'package:appunivalle/core/network/api_exception.dart';
import 'package:appunivalle/features/auth/application/session_controller.dart';
import 'package:appunivalle/features/auth/data/auth_repository.dart';
import 'package:appunivalle/features/auth/data/models/login_request.dart';
import 'package:appunivalle/features/auth/data/models/rol_usuario.dart';
import 'package:appunivalle/features/auth/data/models/token_response.dart';
import 'package:appunivalle/features/auth/data/models/usuario_me.dart';

UsuarioMe _usuario(RolUsuario rol) => UsuarioMe(
      id: '00000000-0000-0000-0000-000000000001',
      email: 'test@est.univalle.edu',
      nombres: 'Test',
      apellidos: 'User',
      rol: rol,
      activo: true,
    );

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.tieneSesion = false,
    this.usuario,
    this.errorAlLogin,
    this.errorAlPerfil,
  });

  bool tieneSesion;
  UsuarioMe? usuario;
  ApiException? errorAlLogin;
  ApiException? errorAlPerfil;
  bool logoutLlamado = false;

  @override
  Future<TokenResponse> login(LoginRequest request) async {
    if (errorAlLogin != null) throw errorAlLogin!;
    tieneSesion = true;
    return const TokenResponse(
        accessToken: 'tok', tokenType: 'bearer', expiraEn: 3600);
  }

  @override
  Future<UsuarioMe> obtenerPerfil() async {
    if (errorAlPerfil != null) throw errorAlPerfil!;
    return usuario!;
  }

  @override
  Future<UsuarioMe> actualizarPerfil({
    required String nombres,
    required String apellidos,
    String? telefono,
  }) async =>
      usuario!;

  @override
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {}

  @override
  Future<void> logout() async {
    logoutLlamado = true;
    tieneSesion = false;
  }

  @override
  Future<bool> haySesion() async => tieneSesion;
}

void main() {
  test('login de estudiante -> autenticado', () async {
    final repo = _FakeAuthRepository(usuario: _usuario(RolUsuario.estudiante));
    final c = SessionController(authRepository: repo);

    await c.login('a@est.univalle.edu', 'x');

    expect(c.status, SessionStatus.autenticado);
    expect(c.usuario?.rol, RolUsuario.estudiante);
  });

  test('login de no-estudiante -> accesoDenegado y limpia sesion', () async {
    final repo = _FakeAuthRepository(usuario: _usuario(RolUsuario.admin));
    final c = SessionController(authRepository: repo);

    await c.login('admin@univalle.edu', 'x');

    expect(c.status, SessionStatus.accesoDenegado);
    expect(c.usuario, isNull);
    expect(repo.logoutLlamado, isTrue);
  });

  test('login con credenciales malas -> noAutenticado + mensaje', () async {
    final repo = _FakeAuthRepository(
      errorAlLogin:
          const ApiException(statusCode: 401, message: 'Credenciales invalidas.'),
    );
    final c = SessionController(authRepository: repo);

    await c.login('a', 'b');

    expect(c.status, SessionStatus.noAutenticado);
    expect(c.errorMessage, 'Credenciales invalidas.');
  });

  test('cargarSesion sin token -> noAutenticado', () async {
    final repo = _FakeAuthRepository(tieneSesion: false);
    final c = SessionController(authRepository: repo);

    await c.cargarSesion();

    expect(c.status, SessionStatus.noAutenticado);
  });

  test('cargarSesion con token de estudiante -> autenticado', () async {
    final repo = _FakeAuthRepository(
      tieneSesion: true,
      usuario: _usuario(RolUsuario.estudiante),
    );
    final c = SessionController(authRepository: repo);

    await c.cargarSesion();

    expect(c.status, SessionStatus.autenticado);
  });

  test('cargarSesion con token vencido (401) -> noAutenticado y logout',
      () async {
    final repo = _FakeAuthRepository(
      tieneSesion: true,
      errorAlPerfil:
          const ApiException(statusCode: 401, message: 'Token invalido'),
    );
    final c = SessionController(authRepository: repo);

    await c.cargarSesion();

    expect(c.status, SessionStatus.noAutenticado);
    expect(repo.logoutLlamado, isTrue);
  });
}
