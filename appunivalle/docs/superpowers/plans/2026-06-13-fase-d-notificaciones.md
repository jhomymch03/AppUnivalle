# Fase D — Notificaciones Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar al estudiante una campana con badge + pantalla de notificaciones (consumiendo los endpoints in-app del backend) y, mientras la app está en primer plano, un aviso del sistema con sonido cuando llega una notificación nueva.

**Architecture:** Feature-First sobre Dio. La lógica pura (parseo, mapeo tipo→ícono, detección de ids nuevos) va en funciones testeables. Un `NotificacionesController` (ChangeNotifier, Provider) hace polling cada 60 s en primer plano, detecta notificaciones nuevas y dispara una notificación local con sonido (`flutter_local_notifications`). La campana vive en las AppBars; el ciclo de vida (arranque/parada/pausa) se cablea en `app.dart` según la sesión y el lifecycle.

**Tech Stack:** Flutter, Dio 5.7, provider 6.1, go_router 14.6, flutter_local_notifications (nuevo). Tests con flutter_test.

> **Solo backend existente:** se usan `GET /notificaciones/mis`, `GET /notificaciones/contar-no-leidas`, `PATCH /notificaciones/{id}/leer`, `POST /notificaciones/marcar-todas-leidas`. NO se toca el backend. Push real con la app cerrada (FCM) queda fuera de alcance (necesita backend).

> **Sin git:** no es repositorio git; cada tarea termina con checkpoint de `analyze`/`test` (no commit). `flutter analyze` sale con código != 0 ante cualquier `info`; los ~9 `prefer_initializing_formals` existentes son aceptables — solo importan errores/warnings o infos nuevos no intencionales.

---

## Estructura de archivos

**Crear:**
- `lib/features/notificaciones/data/models/notificacion.dart` — modelo `Notificacion`.
- `lib/features/notificaciones/data/notificaciones_repository.dart` — repositorio.
- `lib/features/notificaciones/application/tipo_notificacion.dart` — `estiloNotificacion(tipo)`.
- `lib/features/notificaciones/application/deteccion_nuevas.dart` — `idsNuevas(...)`.
- `lib/features/notificaciones/application/local_notificaciones_service.dart` — wrapper de `flutter_local_notifications`.
- `lib/features/notificaciones/application/notificaciones_controller.dart` — estado + polling.
- `lib/features/notificaciones/presentation/notifications_bell.dart` — campana de AppBar.
- `lib/features/notificaciones/presentation/notificaciones_screen.dart` — pantalla lista.
- `test/notificacion_test.dart`, `test/tipo_notificacion_test.dart`, `test/deteccion_nuevas_test.dart`.

**Modificar:**
- `pubspec.yaml` — agrega `flutter_local_notifications`.
- `android/app/src/main/AndroidManifest.xml` — permiso `POST_NOTIFICATIONS`.
- `lib/core/di/app_dependencies.dart` — registra `NotificacionesRepository`.
- `lib/main.dart` — inicializa el servicio local, pide permiso, crea el controller.
- `lib/app/app.dart` — provee el controller; arranca/para según sesión; pausa/reanuda según lifecycle.
- `lib/app/router.dart` — ruta `/notificaciones`.
- AppBars de las 9 pantallas del estudiante — agregan la campana en `actions`.

---

## Task 1: Dependencia flutter_local_notifications + permiso Android

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Agregar el paquete**

En `pubspec.yaml`, dentro de `dependencies:`, debajo de `url_launcher: ^6.3.0`, agrega:

```yaml
  flutter_local_notifications: ^18.0.1   # aviso del sistema con sonido (foreground)
```

- [ ] **Step 2: Instalar**

Run: `flutter pub get`
Expected: "Got dependencies!". Si hay conflicto de versión con el SDK, usa la última versión `18.x` que `pub` proponga y continúa.

- [ ] **Step 3: Permiso POST_NOTIFICATIONS**

En `android/app/src/main/AndroidManifest.xml`, junto a los `<uses-permission>` existentes (después del de INTERNET), agrega:

```xml
    <!-- Notificaciones locales (Android 13+ exige permiso en runtime). -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze`
Expected: sin errores nuevos.

---

## Task 2: Modelo Notificacion (TDD)

**Files:**
- Create: `lib/features/notificaciones/data/models/notificacion.dart`
- Test: `test/notificacion_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/notificacion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/notificaciones/data/models/notificacion.dart';

void main() {
  test('Notificacion.fromJson mapea campos', () {
    final n = Notificacion.fromJson({
      'id': 'n1',
      'destinatario_id': 'u1',
      'postulacion_id': 'p1',
      'tipo': 'aprobada',
      'titulo': 'Tu propuesta fue aprobada',
      'mensaje': 'Continúa al Módulo 2.',
      'leida': false,
      'fecha_leida': null,
      'created_at': '2026-06-10T12:00:00Z',
    });
    expect(n.id, 'n1');
    expect(n.postulacionId, 'p1');
    expect(n.tipo, 'aprobada');
    expect(n.leida, isFalse);
  });

  test('postulacion_id puede ser null', () {
    final n = Notificacion.fromJson({
      'id': 'n2',
      'destinatario_id': 'u1',
      'postulacion_id': null,
      'tipo': 'recordatorio_ventana',
      'titulo': 'Recordatorio',
      'mensaje': 'Te quedan horas.',
      'leida': true,
      'fecha_leida': '2026-06-10T13:00:00Z',
      'created_at': '2026-06-10T12:00:00Z',
    });
    expect(n.postulacionId, isNull);
    expect(n.leida, isTrue);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/notificacion_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el modelo**

```dart
// lib/features/notificaciones/data/models/notificacion.dart
/// Notificacion in-app — espeja `NotificacionOutput` del backend (solo los
/// campos que la app usa).
library;

class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.createdAt,
    this.postulacionId,
  });

  final String id;
  final String? postulacionId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime createdAt;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as String,
      postulacionId: json['postulacion_id'] as String?,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      leida: json['leida'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/notificacion_test.dart`
Expected: PASS (2 tests).

---

## Task 3: estiloNotificacion (TDD)

**Files:**
- Create: `lib/features/notificaciones/application/tipo_notificacion.dart`
- Test: `test/tipo_notificacion_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/tipo_notificacion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/notificaciones/application/tipo_notificacion.dart';

void main() {
  test('tipo conocido devuelve su icono', () {
    expect(estiloNotificacion('aprobada').icon, Icons.check_circle);
    expect(estiloNotificacion('rechazada').icon, Icons.cancel);
    expect(estiloNotificacion('observacion_recibida').icon, Icons.comment);
  });

  test('tipo desconocido cae al fallback', () {
    expect(estiloNotificacion('algo_raro').icon, Icons.notifications);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/tipo_notificacion_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el helper**

```dart
// lib/features/notificaciones/application/tipo_notificacion.dart
/// Mapea el `tipo` de notificacion del backend a un icono + color, espejo de
/// `utils/notificaciones.ts` del web. Tipo desconocido → fallback neutro.
library;

import 'package:flutter/material.dart';

typedef EstiloNotificacion = ({IconData icon, Color color});

const _porTipo = <String, EstiloNotificacion>{
  'postulacion_enviada': (icon: Icons.send, color: Colors.blue),
  'observacion_recibida': (icon: Icons.comment, color: Colors.amber),
  'aprobada': (icon: Icons.check_circle, color: Colors.green),
  'rechazada': (icon: Icons.cancel, color: Colors.red),
  'pausada_abandono': (icon: Icons.pause_circle, color: Colors.grey),
  'ventana_1dia_reiniciada': (icon: Icons.refresh, color: Colors.purple),
  'recordatorio_ventana': (icon: Icons.schedule, color: Colors.amber),
};

const _fallback = (icon: Icons.notifications, color: Colors.grey);

EstiloNotificacion estiloNotificacion(String tipo) => _porTipo[tipo] ?? _fallback;
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/tipo_notificacion_test.dart`
Expected: PASS (2 tests).

---

## Task 4: idsNuevas (TDD)

**Files:**
- Create: `lib/features/notificaciones/application/deteccion_nuevas.dart`
- Test: `test/deteccion_nuevas_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/deteccion_nuevas_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/notificaciones/data/models/notificacion.dart';
import 'package:appunivalle/features/notificaciones/application/deteccion_nuevas.dart';

Notificacion _n(String id) => Notificacion(
      id: id,
      tipo: 'aprobada',
      titulo: 't',
      mensaje: 'm',
      leida: false,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('devuelve solo los ids no vistos', () {
    final nuevas = idsNuevas({'a', 'b'}, [_n('b'), _n('c'), _n('d')]);
    expect(nuevas, {'c', 'd'});
  });

  test('vacio si no hay nuevos', () {
    expect(idsNuevas({'a', 'b'}, [_n('a'), _n('b')]), isEmpty);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/deteccion_nuevas_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el helper**

```dart
// lib/features/notificaciones/application/deteccion_nuevas.dart
/// Devuelve los ids de notificaciones presentes en [actuales] que no estaban
/// en [vistas]. Usado por el controller para decidir cuales avisar (sonido).
library;

import '../data/models/notificacion.dart';

Set<String> idsNuevas(Set<String> vistas, List<Notificacion> actuales) {
  return actuales
      .map((n) => n.id)
      .where((id) => !vistas.contains(id))
      .toSet();
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/deteccion_nuevas_test.dart`
Expected: PASS (2 tests).

---

## Task 5: NotificacionesRepository

**Files:**
- Create: `lib/features/notificaciones/data/notificaciones_repository.dart`

- [ ] **Step 1: Crear el repositorio**

```dart
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
          if (limit != null) 'limit': limit,
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
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/notificaciones/data`
Expected: sin errores (salvo el `prefer_initializing_formals` del `_dio`, aceptable).

---

## Task 6: LocalNotificacionesService

**Files:**
- Create: `lib/features/notificaciones/application/local_notificaciones_service.dart`

- [ ] **Step 1: Crear el servicio**

```dart
// lib/features/notificaciones/application/local_notificaciones_service.dart
/// Envuelve `flutter_local_notifications` para mostrar avisos del sistema con
/// sonido cuando llega una notificacion nueva (solo en primer plano).
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificacionesService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  int _nextId = 0;

  static const _channelId = 'notificaciones_univalle';
  static const _channelNombre = 'Notificaciones';

  /// Inicializa el plugin y crea el canal Android (con sonido por defecto).
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    const canal = AndroidNotificationChannel(
      _channelId,
      _channelNombre,
      description: 'Avisos del trámite de titulación',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  /// Pide el permiso de notificaciones (Android 13+).
  Future<void> solicitarPermiso() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Muestra una notificación del sistema con sonido.
  Future<void> mostrar(String titulo, String cuerpo) async {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelNombre,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(_nextId++, titulo, cuerpo, detalles);
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/notificaciones/application/local_notificaciones_service.dart`
Expected: sin errores.

---

## Task 7: NotificacionesController

**Files:**
- Create: `lib/features/notificaciones/application/notificaciones_controller.dart`

- [ ] **Step 1: Crear el controller**

```dart
// lib/features/notificaciones/application/notificaciones_controller.dart
/// Estado compartido de notificaciones (Provider). Hace polling cada 60 s en
/// primer plano, detecta notificaciones nuevas y dispara un aviso local con
/// sonido. En la primera carga NO avisa (evita spamear con las viejas).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/notificacion.dart';
import '../data/notificaciones_repository.dart';
import 'deteccion_nuevas.dart';
import 'local_notificaciones_service.dart';

class NotificacionesController extends ChangeNotifier {
  NotificacionesController({
    required NotificacionesRepository repo,
    required LocalNotificacionesService local,
  })  : _repo = repo,
        _local = local;

  final NotificacionesRepository _repo;
  final LocalNotificacionesService _local;

  static const _intervalo = Duration(seconds: 60);

  List<Notificacion> _items = const [];
  int _noLeidas = 0;
  bool _cargando = false;
  String? _error;

  final Set<String> _vistas = {};
  bool _activo = false;
  Timer? _timer;

  List<Notificacion> get items => _items;
  int get noLeidas => _noLeidas;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Primera carga + arranque del polling. Idempotente. NO dispara avisos.
  Future<void> iniciar() async {
    if (_activo) return;
    _activo = true;
    _cargando = true;
    notifyListeners();
    try {
      final lista = await _repo.listarMias();
      _items = lista;
      _vistas
        ..clear()
        ..addAll(lista.map((n) => n.id));
      _noLeidas = lista.where((n) => !n.leida).length;
      _error = null;
    } on Object catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
    _timer = Timer.periodic(_intervalo, (_) => refrescar());
  }

  /// Detiene y limpia (logout).
  void detener() {
    _timer?.cancel();
    _timer = null;
    _activo = false;
    _items = const [];
    _noLeidas = 0;
    _vistas.clear();
    _error = null;
    notifyListeners();
  }

  /// Pausa el polling (app a segundo plano).
  void pausar() {
    _timer?.cancel();
    _timer = null;
  }

  /// Reanuda el polling (app a primer plano) con un refresco inmediato.
  void reanudar() {
    if (!_activo) return;
    refrescar();
    _timer ??= Timer.periodic(_intervalo, (_) => refrescar());
  }

  /// Relee la lista; avisa (sonido) por cada notificación nueva.
  Future<void> refrescar() async {
    try {
      final lista = await _repo.listarMias();
      final nuevas = idsNuevas(_vistas, lista);
      for (final n in lista.where((n) => nuevas.contains(n.id))) {
        await _local.mostrar(n.titulo, n.mensaje);
      }
      _items = lista;
      _vistas
        ..clear()
        ..addAll(lista.map((n) => n.id));
      _noLeidas = lista.where((n) => !n.leida).length;
      _error = null;
      notifyListeners();
    } on Object catch (e) {
      // El polling falla en silencio; guardamos el error por si la pantalla lo usa.
      _error = e.toString();
    }
  }

  Future<void> marcarLeida(String id) async {
    await _repo.marcarLeida(id);
    await refrescar();
  }

  Future<void> marcarTodasLeidas() async {
    await _repo.marcarTodasLeidas();
    await refrescar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/notificaciones/application/notificaciones_controller.dart`
Expected: sin errores.

---

## Task 8: Wiring (DI + main + app.dart)

**Files:**
- Modify: `lib/core/di/app_dependencies.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/app.dart`

- [ ] **Step 1: Registrar el repo en AppDependencies**

En `lib/core/di/app_dependencies.dart`:

Import (junto a los demás de features):

```dart
import '../../features/notificaciones/data/notificaciones_repository.dart';
```

Campo (después de `final CarrerasRepository carrerasRepository;`):

```dart
  final NotificacionesRepository notificacionesRepository;
```

Parámetro del constructor privado (después de `required this.carrerasRepository,`):

```dart
    required this.notificacionesRepository,
```

En `create()`, después de crear `carrerasRepository`:

```dart
    final notificacionesRepository = NotificacionesRepository(dio: apiClient.dio);
```

En el `return AppDependencies._(...)`, después de `carrerasRepository: carrerasRepository,`:

```dart
      notificacionesRepository: notificacionesRepository,
```

- [ ] **Step 2: Inicializar servicio + controller en main.dart**

Reemplaza el contenido de `lib/main.dart` por:

```dart
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/app_dependencies.dart';
import 'features/auth/application/session_controller.dart';
import 'features/notificaciones/application/local_notificaciones_service.dart';
import 'features/notificaciones/application/notificaciones_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deps = await AppDependencies.create();

  final session = SessionController(authRepository: deps.authRepository);
  deps.setUnauthorizedHandler(session.onTokenRejected);

  // Notificaciones locales (aviso del sistema con sonido en primer plano).
  final localNotifs = LocalNotificacionesService();
  await localNotifs.init();
  await localNotifs.solicitarPermiso();
  final notificaciones = NotificacionesController(
    repo: deps.notificacionesRepository,
    local: localNotifs,
  );

  runApp(AppUnivalle(
    dependencies: deps,
    session: session,
    notificaciones: notificaciones,
  ));
}
```

- [ ] **Step 3: Cablear el controller en app.dart (provider + sesión + lifecycle)**

Reemplaza el contenido de `lib/app/app.dart` por:

```dart
/// Raiz de la aplicacion.
///
/// Provee dependencias, sesion y notificaciones al arbol; crea el router una
/// vez; dispara el auto-login; y controla el ciclo de vida del polling de
/// notificaciones (arranca al autenticarse, para al cerrar sesion, pausa/reanuda
/// con el lifecycle de la app).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/di/app_dependencies.dart';
import '../features/auth/application/session_controller.dart';
import '../features/notificaciones/application/notificaciones_controller.dart';
import 'router.dart';

class AppUnivalle extends StatefulWidget {
  const AppUnivalle({
    super.key,
    required this.dependencies,
    required this.session,
    required this.notificaciones,
  });

  final AppDependencies dependencies;
  final SessionController session;
  final NotificacionesController notificaciones;

  @override
  State<AppUnivalle> createState() => _AppUnivalleState();
}

class _AppUnivalleState extends State<AppUnivalle> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = crearRouter(widget.session);
    WidgetsBinding.instance.addObserver(this);
    widget.session.addListener(_onSessionChanged);
    widget.session.cargarSesion();
  }

  void _onSessionChanged() {
    if (widget.session.status == SessionStatus.autenticado) {
      widget.notificaciones.iniciar();
    } else {
      widget.notificaciones.detener();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.notificaciones.reanudar();
    } else if (state == AppLifecycleState.paused) {
      widget.notificaciones.pausar();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: widget.dependencies),
        ChangeNotifierProvider<SessionController>.value(value: widget.session),
        ChangeNotifierProvider<NotificacionesController>.value(
          value: widget.notificaciones,
        ),
      ],
      child: MaterialApp.router(
        title: 'AppUnivalle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade700),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
```

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze lib/core/di/app_dependencies.dart lib/main.dart lib/app/app.dart`
Expected: sin errores.

---

## Task 9: NotificationsBell + NotificacionesScreen + ruta

**Files:**
- Create: `lib/features/notificaciones/presentation/notifications_bell.dart`
- Create: `lib/features/notificaciones/presentation/notificaciones_screen.dart`
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Crear la campana**

```dart
// lib/features/notificaciones/presentation/notifications_bell.dart
/// Campana de la AppBar con badge de no leídas. Observa el
/// NotificacionesController; al tocar navega a la pantalla de notificaciones.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/notificaciones_controller.dart';

class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final noLeidas = context.watch<NotificacionesController>().noLeidas;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notificaciones'),
        ),
        if (noLeidas > 0)
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                noLeidas > 9 ? '9+' : '$noLeidas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Crear la pantalla**

```dart
// lib/features/notificaciones/presentation/notificaciones_screen.dart
/// Pantalla de notificaciones del estudiante: lista (icono por tipo, titulo,
/// mensaje, fecha relativa, punto si no leida), marcar todas, pull-to-refresh.
/// Tocar una la marca leida y navega a la postulacion del estudiante.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formato.dart';
import '../application/notificaciones_controller.dart';
import '../application/tipo_notificacion.dart';
import '../data/models/notificacion.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificacionesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (ctrl.noLeidas > 0)
            TextButton(
              onPressed: () => context
                  .read<NotificacionesController>()
                  .marcarTodasLeidas(),
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificacionesController>().refrescar(),
        child: _cuerpo(context, ctrl),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, NotificacionesController ctrl) {
    if (ctrl.cargando && ctrl.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ctrl.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                ctrl.error ?? 'No tienes notificaciones todavía.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: ctrl.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _tile(context, ctrl.items[i]),
    );
  }

  Widget _tile(BuildContext context, Notificacion n) {
    final estilo = estiloNotificacion(n.tipo);
    return ListTile(
      leading: Icon(estilo.icon, color: estilo.color),
      title: Text(
        n.titulo,
        style: TextStyle(
            fontWeight: n.leida ? FontWeight.normal : FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.mensaje),
          const SizedBox(height: 2),
          Text(fechaRelativa(n.createdAt),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: n.leida
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: Colors.red.shade700, shape: BoxShape.circle),
            ),
      onTap: () async {
        final ctrl = context.read<NotificacionesController>();
        if (!n.leida) {
          try {
            await ctrl.marcarLeida(n.id);
          } on Object {
            // silencioso: no bloquea la navegación
          }
        }
        if (!context.mounted) return;
        if (n.postulacionId != null) {
          context.push('/postulacion/nueva');
        }
      },
    );
  }
}
```

- [ ] **Step 3: Agregar la ruta**

En `lib/app/router.dart`:

Import (junto a las demás pantallas):

```dart
import '../features/notificaciones/presentation/notificaciones_screen.dart';
```

Constante (después de `static const perfil = '/perfil';`):

```dart
  static const notificaciones = '/notificaciones';
```

`GoRoute` (después de la ruta `Rutas.perfil`):

```dart
      GoRoute(
        path: Rutas.notificaciones,
        builder: (_, _) => const NotificacionesScreen(),
      ),
```

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze lib/features/notificaciones/presentation lib/app/router.dart`
Expected: sin errores.

---

## Task 10: Agregar la campana a las AppBars del estudiante

**Files:**
- Modify (9): `home_estudiante_screen.dart`, `mis_postulaciones_screen.dart`, `postulacion_detalle_screen.dart`, `postulacion_form_screen.dart`, `observaciones_screen.dart`, `historial_screen.dart`, `documentos_screen.dart`, `carta_respuesta_screen.dart`, `perfil_screen.dart`

- [ ] **Step 1: Agregar el import y la acción en cada pantalla**

En cada uno de los 9 archivos (todos bajo `lib/features/.../presentation/`), haz dos cambios:

(a) Agrega el import (ajusta la profundidad de `../` según la ubicación del archivo; para los que están en `lib/features/postulaciones/presentation/` y `lib/features/estudiante/presentation/` y `lib/features/perfil/presentation/` es `../../notificaciones/presentation/notifications_bell.dart`):

```dart
import '../../notificaciones/presentation/notifications_bell.dart';
```

(b) En su `AppBar`, agrega `actions: const [NotificationsBell()],`. Ejemplo concreto (Mis Postulaciones):

```dart
// Antes:
appBar: AppBar(title: const Text('Mis Postulaciones')),
// Después:
appBar: AppBar(
  title: const Text('Mis Postulaciones'),
  actions: const [NotificationsBell()],
),
```

Aplica el mismo patrón a cada pantalla, respetando su título actual:
- `home_estudiante_screen.dart` → AppBar 'Inicio' (ya tiene `drawer`; agrega `actions`).
- `mis_postulaciones_screen.dart` → 'Mis Postulaciones'.
- `postulacion_detalle_screen.dart` → 'Detalle'.
- `postulacion_form_screen.dart` → el título dinámico ('Nueva postulación'/'Mi postulación'); agrega `actions: const [NotificationsBell()],`.
- `observaciones_screen.dart` → 'Observaciones'.
- `historial_screen.dart` → 'Historial'.
- `documentos_screen.dart` → 'Documentos'.
- `carta_respuesta_screen.dart` → 'Carta de Respuesta'.
- `perfil_screen.dart` → 'Mi cuenta'.

> No agregues la campana a `NotificacionesScreen` (ya estás ahí) ni a las pantallas de auth (login/splash/acceso-denegado/configuración de servidor).

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze`
Expected: solo los `info - prefer_initializing_formals` conocidos (su número crece con `notificaciones_repository.dart`). Cero errores/warnings.

---

## Task 11: Verificación final

**Files:** —

- [ ] **Step 1: Análisis estático completo**

Run: `flutter analyze`
Expected: solo `info - prefer_initializing_formals`. Cero errores/warnings, cero infos de otro tipo.

- [ ] **Step 2: Toda la batería de tests**

Run: `flutter test`
Expected: todo en verde (nuevos: notificacion, tipo_notificacion, deteccion_nuevas; más los previos).

- [ ] **Step 3: Prueba manual en el teléfono (guía)**

Run: `flutter run --dart-define=API_BASE_URL=https://TU-URL.trycloudflare.com`

Verifica:
1. Al loguear, en la barra superior aparece la **campana**; si tienes no leídas, muestra el **badge** con el número.
2. Tocar la campana abre la **pantalla de Notificaciones**; pull-to-refresh recarga; "Marcar todas" pone el badge en 0.
3. Tocar una notificación la marca leída (desaparece el punto) y navega a tu postulación.
4. Con la app abierta, si llega una notificación nueva (p. ej. la secretaría observa tu postulación desde el web), en ≤60 s **suena y aparece un aviso del sistema** en la bandeja; las que ya existían al abrir la app **no** disparan aviso.
5. Acepta el permiso de notificaciones cuando Android lo pida (primera vez).

---

## Self-review (cobertura del spec)

- Campana con badge en AppBar → Tasks 9, 10. ✅
- Pantalla con lista, marcar todas, pull-to-refresh, tap→leer+navegar → Task 9. ✅
- Repositorio con los 4 endpoints reales → Task 5. ✅
- Polling 60 s en primer plano, sin spamear en 1ª carga, detección de nuevas → Task 7 (usa `idsNuevas` de Task 4). ✅
- Aviso local con sonido + permiso Android → Tasks 1, 6. ✅
- Tipo→ícono/color con fallback → Task 3. ✅
- Wiring (DI, main, ciclo de vida/sesión) → Task 8. ✅
- Errores: polling silencioso, pantalla con estado de error → Tasks 7, 9. ✅
- Tests (modelo, estilo+fallback, idsNuevas) → Tasks 2, 3, 4. ✅
- Fuera de alcance (push real FCM) → no implementado, documentado. ✅
