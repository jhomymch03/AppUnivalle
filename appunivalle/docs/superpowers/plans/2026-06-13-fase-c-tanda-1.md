# Fase C — Tanda 1 (Drawer + Crear/Editar/Enviar) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar al estudiante la navegación lateral (Navigation Drawer) y el flujo de escritura de su postulación (crear, editar, subir PDFs, enviar a secretaría), replicando exactamente la interfaz web del estudiante.

**Architecture:** Feature-First sobre el `ApiClient`/Dio ya existente. La lógica testeable (validación, armado de payload, cruce de tutores, fallback de modalidades, selección de postulación activa) vive en funciones/clases puras con tests unitarios; los repositorios solo hacen HTTP + delegan en esas funciones. El Drawer se comparte agregando `drawer: const AppDrawer()` al `Scaffold` de cada pantalla del estudiante (en lugar de un `ShellRoute`), para no refactorizar las pantallas de Fase B que ya funcionan; es equivalente en UX y menos riesgoso.

**Tech Stack:** Flutter, Dio 5.7, provider 6.1, go_router 14.6, file_picker (nuevo). Tests con flutter_test.

> **Nota sobre commits:** este proyecto **no es un repositorio git** (`git: false`). Por eso cada tarea termina con un **checkpoint de verificación** (`flutter analyze` y/o `flutter test`) en vez de un `git commit`. Si más adelante se inicializa git, conviértelos en commits.

> **Refinamiento respecto al spec:** el spec mencionaba "PATCH solo campos tocados". Al revisar el web (`Postulacion.vue` → `submitGuardar` llama `editar(id, toCreateInput(vals))`), el web envía el **cuerpo completo** también en PATCH (con `null` en los campos del tutor que no aplica). El backend lo resuelve con `model_fields_set`. Para paridad exacta y simplicidad, este plan envía el **cuerpo completo** en crear y en editar con el mismo `toJson()`.

---

## Estructura de archivos

**Crear:**
- `lib/features/postulaciones/application/postulacion_actual.dart` — helpers puros (`pickActiva`, `esEditable`).
- `lib/features/postulaciones/data/models/postulacion_form_data.dart` — estado del formulario + `validar()` + `toJson()`.
- `lib/features/archivos/data/models/archivo_subido.dart` — modelo de respuesta de subida.
- `lib/features/archivos/data/archivos_repository.dart` — `subir(...)`.
- `lib/features/catalogos/data/models/tutor_option.dart` — `TutorOption` + `construirOpcionesTutor(...)`.
- `lib/features/catalogos/data/tutores_repository.dart` — `listarOpcionesTutor()`.
- `lib/features/catalogos/data/modalidades_repository.dart` — `listar()` + `kModalidadesFallback` + `modalidadesDesdeJson(...)`.
- `lib/features/shell/presentation/app_drawer.dart` — Navigation Drawer compartido.
- `lib/features/archivos/presentation/archivo_upload_field.dart` — widget de subida de PDF.
- `lib/features/postulaciones/presentation/postulacion_form_screen.dart` — formulario crear/editar/enviar.
- `lib/features/postulaciones/presentation/observaciones_screen.dart` — observaciones de la activa.
- `lib/features/postulaciones/presentation/historial_screen.dart` — timeline de todas.
- `test/postulacion_actual_test.dart`, `test/postulacion_form_data_test.dart`, `test/tutor_option_test.dart`, `test/modalidades_test.dart`.

**Modificar:**
- `pubspec.yaml` — agrega `file_picker`.
- `lib/features/postulaciones/data/models/postulacion.dart` — agrega `tutorDocenteId`, `tutorExternoCi`, `tutorExternoTelefono`.
- `lib/features/postulaciones/data/postulaciones_repository.dart` — agrega `crear`, `editar`, `enviarASecretaria`.
- `lib/core/di/app_dependencies.dart` — registra los 3 repos nuevos.
- `lib/app/router.dart` — agrega rutas `/postulacion/nueva`, `/observaciones`, `/historial`.
- `lib/features/estudiante/presentation/home_estudiante_screen.dart` — drawer + botones contextuales.
- `lib/features/postulaciones/presentation/mis_postulaciones_screen.dart` — agrega drawer.

---

## Task 1: Agregar dependencia file_picker

**Files:**
- Modify: `pubspec.yaml:43-45`

- [ ] **Step 1: Agregar el paquete en la sección de navegación/estado**

En `pubspec.yaml`, dentro de `dependencies:`, después de `go_router: ^14.6.2`, agrega:

```yaml
  # --- Archivos ---
  file_picker: ^8.1.2          # selector de PDF para adjuntar (tutor externo)
```

- [ ] **Step 2: Instalar**

Run: `flutter pub get`
Expected: "Got dependencies!" sin errores de resolución.

- [ ] **Step 3: Checkpoint**

Run: `flutter analyze`
Expected: sin errores nuevos (los `info - prefer_initializing_formals` previos son aceptables).

---

## Task 2: Ampliar el modelo Postulacion con los campos del formulario

El formulario prellena desde la postulación activa; el modelo actual no expone `tutor_docente_id`, `tutor_externo_ci` ni `tutor_externo_telefono`.

**Files:**
- Modify: `lib/features/postulaciones/data/models/postulacion.dart`

- [ ] **Step 1: Agregar los campos al constructor y a la clase**

En el constructor (después de `this.tutorExternoApellidos,`) agrega `this.tutorDocenteId,`, y junto a los demás opcionales agrega `this.tutorExternoCi,` y `this.tutorExternoTelefono,`.

En la declaración de campos, junto a los tutor externo existentes, agrega:

```dart
  final String? tutorDocenteId;
  final String? tutorExternoCi;
  final String? tutorExternoTelefono;
```

- [ ] **Step 2: Mapear en fromJson**

Dentro de `Postulacion.fromJson`, después de `tutorExternoApellidos: ...,` agrega:

```dart
      tutorDocenteId: json['tutor_docente_id'] as String?,
      tutorExternoCi: json['tutor_externo_ci'] as String?,
      tutorExternoTelefono: json['tutor_externo_telefono'] as String?,
```

- [ ] **Step 3: Checkpoint**

Run: `flutter test test/postulacion_model_test.dart`
Expected: PASS (los tests existentes siguen verdes; los campos nuevos son opcionales).

---

## Task 3: Helpers de postulación activa (TDD)

**Files:**
- Create: `lib/features/postulaciones/application/postulacion_actual.dart`
- Test: `test/postulacion_actual_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/postulacion_actual_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/estado_postulacion.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion.dart';
import 'package:appunivalle/features/postulaciones/application/postulacion_actual.dart';

Postulacion _p({required String id, required String estado, required String createdAt}) {
  return Postulacion.fromJson({
    'id': id,
    'codigo': null,
    'titulo': 'T',
    'descripcion': 'Una descripcion larga.',
    'modalidad': 'Tesis',
    'tipo_tutor': 'interno',
    'estado_actual': estado,
    'created_at': createdAt,
    'updated_at': createdAt,
  });
}

void main() {
  test('pickActiva devuelve la mas reciente no rechazada', () {
    final lista = [
      _p(id: 'a', estado: 'BORRADOR', createdAt: '2026-01-01T00:00:00Z'),
      _p(id: 'b', estado: 'OBSERVADO_SECRETARIA', createdAt: '2026-03-01T00:00:00Z'),
      _p(id: 'c', estado: 'RECHAZADO', createdAt: '2026-06-01T00:00:00Z'),
    ];
    expect(pickActiva(lista)?.id, 'b');
  });

  test('pickActiva devuelve null si todas estan rechazadas o no hay', () {
    expect(pickActiva(const []), isNull);
    expect(
      pickActiva([_p(id: 'a', estado: 'RECHAZADO', createdAt: '2026-01-01T00:00:00Z')]),
      isNull,
    );
  });

  test('esEditable solo en BORRADOR / OBSERVADO_*', () {
    expect(esEditable(EstadoPostulacion.borrador), isTrue);
    expect(esEditable(EstadoPostulacion.observadoSecretaria), isTrue);
    expect(esEditable(EstadoPostulacion.observadoDireccion), isTrue);
    expect(esEditable(EstadoPostulacion.enviadoASecretaria), isFalse);
    expect(esEditable(EstadoPostulacion.aprobado), isFalse);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/postulacion_actual_test.dart`
Expected: FAIL ("Target of URI doesn't exist" / `pickActiva` no definido).

- [ ] **Step 3: Implementar los helpers**

```dart
// lib/features/postulaciones/application/postulacion_actual.dart
/// Helpers puros sobre la lista de postulaciones del estudiante.
///
/// Replican la convencion del web (`usePostulacionActual`): existe UNA
/// postulacion "activa" — la mas reciente que NO esta rechazada. Y solo
/// ciertos estados son editables.
library;

import '../data/models/estado_postulacion.dart';
import '../data/models/postulacion.dart';

/// Estados en los que el formulario es editable y se puede (re)enviar.
const _estadosEditables = <EstadoPostulacion>{
  EstadoPostulacion.borrador,
  EstadoPostulacion.observadoSecretaria,
  EstadoPostulacion.observadoDireccion,
};

/// La postulacion activa: la mas reciente (por `createdAt`) que no este
/// RECHAZADA. `null` si no hay ninguna o todas estan rechazadas.
Postulacion? pickActiva(List<Postulacion> items) {
  final candidatas = items
      .where((p) => p.estado != EstadoPostulacion.rechazado)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return candidatas.isEmpty ? null : candidatas.first;
}

/// `true` si en ese estado el estudiante puede editar y (re)enviar.
bool esEditable(EstadoPostulacion estado) => _estadosEditables.contains(estado);
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/postulacion_actual_test.dart`
Expected: PASS (3 tests).

---

## Task 4: PostulacionFormData — validación y payload (TDD)

**Files:**
- Create: `lib/features/postulaciones/data/models/postulacion_form_data.dart`
- Test: `test/postulacion_form_data_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/postulacion_form_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/postulaciones/data/models/tipo_tutor.dart';
import 'package:appunivalle/features/postulaciones/data/models/postulacion_form_data.dart';

void main() {
  PostulacionFormData base() => PostulacionFormData(
        titulo: 'Sistema de gestion academica',
        descripcion: 'Descripcion suficientemente larga.',
        modalidad: 'Tesis',
        tipoTutor: TipoTutor.interno,
        tutorDocenteId: 'doc-1',
      );

  test('valida titulo, descripcion y modalidad', () {
    final f = base()..titulo = 'abc'; // < 5
    final e = f.validar();
    expect(e['titulo'], isNotNull);
  });

  test('interno requiere docente', () {
    final f = base()..tutorDocenteId = null;
    expect(f.validar()['tutorDocenteId'], isNotNull);
  });

  test('externo requiere nombres y apellidos', () {
    final f = PostulacionFormData(
      titulo: 'Titulo valido',
      descripcion: 'Descripcion larga valida.',
      modalidad: 'Tesis',
      tipoTutor: TipoTutor.externo,
    );
    final e = f.validar();
    expect(e['tutorExternoNombres'], isNotNull);
    expect(e['tutorExternoApellidos'], isNotNull);
  });

  test('toJson interno limpia los campos de tutor externo', () {
    final f = base()..tutorDocenteId = 'doc-9';
    final json = f.toJson();
    expect(json['tipo_tutor'], 'interno');
    expect(json['tutor_docente_id'], 'doc-9');
    expect(json['tutor_externo_nombres'], isNull);
    expect(json['tutor_externo_cv_archivo_id'], isNull);
  });

  test('toJson externo limpia tutor_docente_id', () {
    final f = PostulacionFormData(
      titulo: 'Titulo valido',
      descripcion: 'Descripcion larga valida.',
      modalidad: 'Tesis',
      tipoTutor: TipoTutor.externo,
      tutorExternoNombres: 'Ana',
      tutorExternoApellidos: 'Garcia',
      tutorExternoCvArchivoId: 'cv-1',
    );
    final json = f.toJson();
    expect(json['tipo_tutor'], 'externo');
    expect(json['tutor_docente_id'], isNull);
    expect(json['tutor_externo_nombres'], 'Ana');
    expect(json['tutor_externo_cv_archivo_id'], 'cv-1');
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/postulacion_form_data_test.dart`
Expected: FAIL (clase no definida).

- [ ] **Step 3: Implementar PostulacionFormData**

```dart
// lib/features/postulaciones/data/models/postulacion_form_data.dart
/// Estado mutable del formulario de postulacion + validacion y armado del
/// payload. Espeja `postulacionSchema` y `toCreateInput` del web: la
/// validacion condicional segun `tipoTutor` y la limpieza cruzada de los
/// campos del tutor que no aplica.
library;

import 'tipo_tutor.dart';

class PostulacionFormData {
  PostulacionFormData({
    this.titulo = '',
    this.descripcion = '',
    this.modalidad = '',
    this.tipoTutor = TipoTutor.interno,
    this.tutorDocenteId,
    this.tutorExternoNombres,
    this.tutorExternoApellidos,
    this.tutorExternoCi,
    this.tutorExternoEmail,
    this.tutorExternoTelefono,
    this.tutorExternoCvArchivoId,
    this.tutorExternoTituloArchivoId,
  });

  String titulo;
  String descripcion;
  String modalidad;
  TipoTutor tipoTutor;
  String? tutorDocenteId;
  String? tutorExternoNombres;
  String? tutorExternoApellidos;
  String? tutorExternoCi;
  String? tutorExternoEmail;
  String? tutorExternoTelefono;
  String? tutorExternoCvArchivoId;
  String? tutorExternoTituloArchivoId;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Devuelve un mapa campo->mensaje. Vacio si el formulario es valido.
  Map<String, String> validar() {
    final e = <String, String>{};
    final t = titulo.trim();
    if (t.length < 5) e['titulo'] = 'El titulo debe tener al menos 5 caracteres.';
    if (t.length > 500) e['titulo'] = 'El titulo no puede superar los 500 caracteres.';
    if (descripcion.trim().length < 10) {
      e['descripcion'] = 'La descripcion debe tener al menos 10 caracteres.';
    }
    if (modalidad.trim().length < 3) e['modalidad'] = 'Selecciona una modalidad.';

    if (tipoTutor == TipoTutor.interno) {
      if (tutorDocenteId == null || tutorDocenteId!.isEmpty) {
        e['tutorDocenteId'] = 'Selecciona un tutor de la lista.';
      }
    } else {
      if ((tutorExternoNombres ?? '').trim().length < 2) {
        e['tutorExternoNombres'] = 'Los nombres del tutor externo son obligatorios.';
      }
      if ((tutorExternoApellidos ?? '').trim().length < 2) {
        e['tutorExternoApellidos'] = 'Los apellidos del tutor externo son obligatorios.';
      }
      final email = (tutorExternoEmail ?? '').trim();
      if (email.isNotEmpty && !_emailRe.hasMatch(email)) {
        e['tutorExternoEmail'] = 'Email del tutor invalido.';
      }
    }
    return e;
  }

  /// `true` si no hay errores de validacion.
  bool get esValido => validar().isEmpty;

  String? _limpio(String? v) {
    final s = v?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Cuerpo para POST (crear) y PATCH (editar): igual que el web, envia todos
  /// los campos y pone en `null` los del tutor que no aplica.
  Map<String, dynamic> toJson() {
    final interno = tipoTutor == TipoTutor.interno;
    return {
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'modalidad': modalidad.trim(),
      'tipo_tutor': tipoTutor.wire,
      'tutor_docente_id': interno ? tutorDocenteId : null,
      'tutor_externo_nombres': interno ? null : _limpio(tutorExternoNombres),
      'tutor_externo_apellidos': interno ? null : _limpio(tutorExternoApellidos),
      'tutor_externo_ci': interno ? null : _limpio(tutorExternoCi),
      'tutor_externo_email': interno ? null : _limpio(tutorExternoEmail),
      'tutor_externo_telefono': interno ? null : _limpio(tutorExternoTelefono),
      'tutor_externo_cv_archivo_id': interno ? null : tutorExternoCvArchivoId,
      'tutor_externo_titulo_archivo_id': interno ? null : tutorExternoTituloArchivoId,
    };
  }
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/postulacion_form_data_test.dart`
Expected: PASS (5 tests).

---

## Task 5: Ampliar PostulacionesRepository (crear/editar/enviar)

**Files:**
- Modify: `lib/features/postulaciones/data/postulaciones_repository.dart`

- [ ] **Step 1: Agregar los tres métodos**

Después de `obtenerDetalle(...)` (antes del `}` final de la clase), agrega:

```dart
  /// Crea una postulacion en BORRADOR (`POST /postulaciones`).
  Future<Postulacion> crear(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('/postulaciones', data: body);
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Edita una postulacion en estado editable (`PATCH /postulaciones/{id}`).
  Future<Postulacion> editar(String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/postulaciones/$id',
        data: body,
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Envia (o reenvia) a secretaria (`POST /postulaciones/{id}/enviar-a-secretaria`).
  Future<Postulacion> enviarASecretaria(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/postulaciones/$id/enviar-a-secretaria',
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/data/postulaciones_repository.dart`
Expected: sin errores.

---

## Task 6: Modelo y repositorio de archivos (subida de PDF)

**Files:**
- Create: `lib/features/archivos/data/models/archivo_subido.dart`
- Create: `lib/features/archivos/data/archivos_repository.dart`

- [ ] **Step 1: Crear el modelo ArchivoSubido**

```dart
// lib/features/archivos/data/models/archivo_subido.dart
/// Respuesta de `POST /archivos` (espeja `ArchivoConUrlOutput`): solo los
/// campos que la app necesita.
library;

class ArchivoSubido {
  const ArchivoSubido({
    required this.id,
    required this.nombre,
    required this.url,
  });

  final String id;
  final String nombre;
  final String url;

  factory ArchivoSubido.fromJson(Map<String, dynamic> json) {
    return ArchivoSubido(
      id: json['id'] as String,
      nombre: json['nombre_original'] as String,
      url: json['url'] as String,
    );
  }
}
```

- [ ] **Step 2: Crear el repositorio de archivos**

```dart
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
}
```

- [ ] **Step 3: Checkpoint**

Run: `flutter analyze lib/features/archivos`
Expected: sin errores (`DioMediaType` viene de `package:dio/dio.dart`).

---

## Task 7: TutorOption y cruce habilitados ⨝ docentes (TDD)

**Files:**
- Create: `lib/features/catalogos/data/models/tutor_option.dart`
- Test: `test/tutor_option_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/tutor_option_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/catalogos/data/models/tutor_option.dart';

void main() {
  test('construye opciones cruzando habilitados con docentes', () {
    final habilitados = [
      {'docente_id': 'd1', 'activo': true},
      {'docente_id': 'd2', 'activo': false}, // inactivo -> descartado
      {'docente_id': 'd3', 'activo': true}, // sin match en docentes -> descartado
    ];
    final docentes = [
      {'id': 'd1', 'nombres': 'Ana', 'apellidos': 'Garcia', 'especialidad': 'IA'},
      {'id': 'd2', 'nombres': 'Luis', 'apellidos': 'Perez', 'especialidad': null},
    ];

    final ops = construirOpcionesTutor(habilitados, docentes);

    expect(ops, hasLength(1));
    expect(ops.first.docenteId, 'd1');
    expect(ops.first.nombreCompleto, 'Ana Garcia');
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/tutor_option_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar TutorOption + construirOpcionesTutor**

```dart
// lib/features/catalogos/data/models/tutor_option.dart
/// Opcion de tutor interno para el selector. Igual que el composable
/// `useTutoresHabilitados` del web: cruza `GET /tutores-habilitados` (que solo
/// trae `docente_id`) con `GET /docentes` (que trae el nombre) y arma el label.
library;

class TutorOption {
  const TutorOption({
    required this.docenteId,
    required this.nombreCompleto,
    this.especialidad,
  });

  /// UUID del docente: es lo que va en `tutor_docente_id` del payload.
  final String docenteId;
  final String nombreCompleto;
  final String? especialidad;
}

/// Cruza tutores habilitados (activos) con el catalogo de docentes y devuelve
/// las opciones ordenadas por nombre. Descarta habilitados inactivos o sin
/// docente correspondiente.
List<TutorOption> construirOpcionesTutor(
  List<Map<String, dynamic>> habilitados,
  List<Map<String, dynamic>> docentes,
) {
  final docMap = {for (final d in docentes) d['id'] as String: d};
  final opciones = <TutorOption>[];
  for (final h in habilitados) {
    if (h['activo'] != true) continue;
    final doc = docMap[h['docente_id'] as String?];
    if (doc == null) continue;
    opciones.add(TutorOption(
      docenteId: doc['id'] as String,
      nombreCompleto: '${doc['nombres']} ${doc['apellidos']}',
      especialidad: doc['especialidad'] as String?,
    ));
  }
  opciones.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
  return opciones;
}
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/tutor_option_test.dart`
Expected: PASS.

---

## Task 8: TutoresRepository

**Files:**
- Create: `lib/features/catalogos/data/tutores_repository.dart`

- [ ] **Step 1: Crear el repositorio**

```dart
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
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/catalogos/data/tutores_repository.dart`
Expected: sin errores.

---

## Task 9: Modalidades con fallback (TDD)

**Files:**
- Create: `lib/features/catalogos/data/modalidades_repository.dart`
- Test: `test/modalidades_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/modalidades_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appunivalle/features/catalogos/data/modalidades_repository.dart';

void main() {
  test('mapea nombres del backend', () {
    final nombres = modalidadesDesdeJson([
      {'codigo': 'TES', 'nombre': 'Tesis', 'activa': true},
      {'codigo': 'PG', 'nombre': 'Proyecto de grado', 'activa': true},
    ]);
    expect(nombres, ['Tesis', 'Proyecto de grado']);
  });

  test('lista vacia -> usa el fallback', () {
    expect(modalidadesDesdeJson(const []), kModalidadesFallback);
  });
}
```

- [ ] **Step 2: Correr el test y verlo fallar**

Run: `flutter test test/modalidades_test.dart`
Expected: FAIL (no definido).

- [ ] **Step 3: Implementar el repositorio + helpers**

```dart
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
```

- [ ] **Step 4: Correr el test y verlo pasar**

Run: `flutter test test/modalidades_test.dart`
Expected: PASS (2 tests).

---

## Task 10: Registrar los repos nuevos en AppDependencies

**Files:**
- Modify: `lib/core/di/app_dependencies.dart`

- [ ] **Step 1: Importar los repos**

Después de `import '../../features/postulaciones/data/postulaciones_repository.dart';` agrega:

```dart
import '../../features/archivos/data/archivos_repository.dart';
import '../../features/catalogos/data/modalidades_repository.dart';
import '../../features/catalogos/data/tutores_repository.dart';
```

- [ ] **Step 2: Agregar los campos y al constructor privado**

En el constructor `AppDependencies._({...})`, después de `required this.postulacionesRepository,` agrega:

```dart
    required this.archivosRepository,
    required this.tutoresRepository,
    required this.modalidadesRepository,
```

En la lista de campos `final`, después de `final PostulacionesRepository postulacionesRepository;` agrega:

```dart
  final ArchivosRepository archivosRepository;
  final TutoresRepository tutoresRepository;
  final ModalidadesRepository modalidadesRepository;
```

- [ ] **Step 3: Construirlos en create() y pasarlos al retorno**

En `create()`, después de la línea que crea `postulacionesRepository`, agrega:

```dart
    final archivosRepository = ArchivosRepository(dio: apiClient.dio);
    final tutoresRepository = TutoresRepository(dio: apiClient.dio);
    final modalidadesRepository = ModalidadesRepository(dio: apiClient.dio);
```

En el `return AppDependencies._(...)`, después de `postulacionesRepository: postulacionesRepository,` agrega:

```dart
      archivosRepository: archivosRepository,
      tutoresRepository: tutoresRepository,
      modalidadesRepository: modalidadesRepository,
```

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze lib/core/di/app_dependencies.dart`
Expected: sin errores.

---

## Task 11: AppDrawer (Navigation Drawer compartido)

**Files:**
- Create: `lib/features/shell/presentation/app_drawer.dart`

- [ ] **Step 1: Crear el drawer**

```dart
// lib/features/shell/presentation/app_drawer.dart
/// Navigation Drawer del estudiante. Replica el sidebar del web
/// (`navigation.ts`): 8 items en el mismo orden. Los de la Tanda 2
/// (Documentos, Carta de Respuesta, Perfil) se muestran atenuados como
/// "Proximamente". Resalta el item de la ruta actual.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../auth/application/session_controller.dart';
import '../../configuracion/presentation/server_config_screen.dart';

class _Item {
  const _Item(this.label, this.icon, this.ruta, {this.habilitado = true});
  final String label;
  final IconData icon;
  final String ruta;
  final bool habilitado;
}

const _items = <_Item>[
  _Item('Dashboard', Icons.home_outlined, '/home'),
  _Item('Nueva Postulación', Icons.edit_document, '/postulacion/nueva'),
  _Item('Mis Postulaciones', Icons.list_alt_outlined, '/mis-postulaciones'),
  _Item('Observaciones', Icons.comment_outlined, '/observaciones'),
  _Item('Documentos', Icons.insert_drive_file_outlined, '/documentos',
      habilitado: false),
  _Item('Historial', Icons.history, '/historial'),
  _Item('Carta de Respuesta', Icons.mail_outline, '/carta-respuesta',
      habilitado: false),
  _Item('Perfil', Icons.person_outline, '/perfil', habilitado: false),
];

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessionController>().usuario;
    final actual = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                '${usuario?.nombres ?? ''} ${usuario?.apellidos ?? ''}'.trim(),
              ),
              accountEmail: Text(usuario?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.school_outlined),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in _items)
                    ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      enabled: item.habilitado,
                      selected: item.habilitado && actual == item.ruta,
                      trailing: item.habilitado
                          ? null
                          : const Text('Próximamente',
                              style: TextStyle(fontSize: 11)),
                      onTap: item.habilitado
                          ? () {
                              Navigator.of(context).pop();
                              if (actual != item.ruta) context.go(item.ruta);
                            }
                          : null,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('Servidor'),
              onTap: () {
                final deps = context.read<AppDependencies>();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServerConfigScreen(dependencies: deps),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<SessionController>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/shell/presentation/app_drawer.dart`
Expected: sin errores. (Si `usuario` no expone `apellidos`, usar solo `nombres`; verificar el modelo de sesión en `session_controller.dart`.)

---

## Task 12: Rutas nuevas en el router

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Importar las pantallas nuevas**

Después de `import '../features/postulaciones/presentation/postulacion_detalle_screen.dart';` agrega:

```dart
import '../features/postulaciones/presentation/postulacion_form_screen.dart';
import '../features/postulaciones/presentation/observaciones_screen.dart';
import '../features/postulaciones/presentation/historial_screen.dart';
```

- [ ] **Step 2: Agregar constantes de ruta**

En `abstract final class Rutas`, después de `static const misPostulaciones = '/mis-postulaciones';` agrega:

```dart
  static const nuevaPostulacion = '/postulacion/nueva';
  static const observaciones = '/observaciones';
  static const historial = '/historial';
```

- [ ] **Step 3: Agregar las rutas**

En la lista `routes:`, después de la ruta `Rutas.misPostulaciones`, agrega (ANTES de la ruta dinámica `'/postulacion/:id'`, para que `/postulacion/nueva` no sea capturada como `:id`):

```dart
      GoRoute(
        path: Rutas.nuevaPostulacion,
        builder: (_, _) => const PostulacionFormScreen(),
      ),
      GoRoute(
        path: Rutas.observaciones,
        builder: (_, _) => const ObservacionesScreen(),
      ),
      GoRoute(
        path: Rutas.historial,
        builder: (_, _) => const HistorialScreen(),
      ),
```

- [ ] **Step 4: Checkpoint (tras crear las pantallas en Tasks 14-16)**

Run: `flutter analyze lib/app/router.dart`
Expected: sin errores una vez existan las 3 pantallas.

---

## Task 13: ArchivoUploadField (widget de subida)

**Files:**
- Create: `lib/features/archivos/presentation/archivo_upload_field.dart`

- [ ] **Step 1: Crear el widget**

```dart
// lib/features/archivos/presentation/archivo_upload_field.dart
/// Campo para adjuntar un PDF: elige archivo (file_picker), lo sube
/// (`ArchivosRepository`) y reporta el id resultante via [onChanged]. Muestra
/// el estado (subiendo / listo / error) y permite quitarlo.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';

class ArchivoUploadField extends StatefulWidget {
  const ArchivoUploadField({
    super.key,
    required this.label,
    required this.archivoId,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? archivoId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<ArchivoUploadField> createState() => _ArchivoUploadFieldState();
}

class _ArchivoUploadFieldState extends State<ArchivoUploadField> {
  bool _subiendo = false;
  String? _nombre;
  String? _error;

  Future<void> _elegir() async {
    setState(() => _error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return; // cancelado
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'No se pudo leer el archivo.');
      return;
    }

    setState(() {
      _subiendo = true;
      _nombre = file.name;
    });
    try {
      final repo = context.read<AppDependencies>().archivosRepository;
      final subido = await repo.subir(bytes: bytes, nombre: file.name);
      widget.onChanged(subido.id);
      setState(() => _subiendo = false);
    } on ApiException catch (e) {
      setState(() {
        _subiendo = false;
        _nombre = null;
        _error = e.message;
      });
    }
  }

  void _quitar() {
    setState(() {
      _nombre = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final tieneArchivo = widget.archivoId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (_subiendo)
          const Row(
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Subiendo...'),
            ],
          )
        else if (tieneArchivo)
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_nombre ?? 'Archivo adjunto',
                    overflow: TextOverflow.ellipsis),
              ),
              if (widget.enabled)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Quitar',
                  onPressed: _quitar,
                ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: widget.enabled ? _elegir : null,
            icon: const Icon(Icons.upload_file),
            label: const Text('Adjuntar PDF'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/archivos/presentation/archivo_upload_field.dart`
Expected: sin errores.

---

## Task 14: PostulacionFormScreen (crear / editar / enviar)

**Files:**
- Create: `lib/features/postulaciones/presentation/postulacion_form_screen.dart`

- [ ] **Step 1: Crear la pantalla**

```dart
// lib/features/postulaciones/presentation/postulacion_form_screen.dart
/// Formulario de postulacion (Fase C). Crea si no hay activa, edita si la hay,
/// y permite enviar a secretaria. Replica `Postulacion.vue` del web: datos del
/// proyecto, tutor interno/externo, declaracion de veracidad y readonly segun
/// estado.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../archivos/presentation/archivo_upload_field.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/postulacion.dart';
import '../data/models/postulacion_form_data.dart';
import '../data/models/tipo_tutor.dart';
import 'widgets/estado_badge.dart';
import 'widgets/estado_banner.dart';
import 'widgets/stepper_proceso.dart';

class PostulacionFormScreen extends StatefulWidget {
  const PostulacionFormScreen({super.key});

  @override
  State<PostulacionFormScreen> createState() => _PostulacionFormScreenState();
}

class _PostulacionFormScreenState extends State<PostulacionFormScreen> {
  late Future<void> _carga;

  Postulacion? _activa;
  List<String> _modalidades = const [];
  List<({String id, String nombre})> _tutores = const [];

  final _form = PostulacionFormData();
  Map<String, String> _errores = const {};
  bool _declaracion = false;
  bool _guardando = false;
  bool _enviando = false;

  bool get _editable => _activa == null || esEditable(_activa!.estado);

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<void> _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    final mods = await deps.modalidadesRepository.listar();
    final ops = await deps.tutoresRepository.listarOpcionesTutor();

    _modalidades = mods;
    _tutores =
        ops.map((o) => (id: o.docenteId, nombre: o.nombreCompleto)).toList();
    _activa = pickActiva(lista);

    final a = _activa;
    if (a != null) {
      _form
        ..titulo = a.titulo
        ..descripcion = a.descripcion
        ..modalidad = a.modalidad
        ..tipoTutor = a.tipoTutor
        ..tutorDocenteId = a.tutorDocenteId
        ..tutorExternoNombres = a.tutorExternoNombres
        ..tutorExternoApellidos = a.tutorExternoApellidos
        ..tutorExternoCi = a.tutorExternoCi
        ..tutorExternoEmail = a.tutorExternoEmail
        ..tutorExternoTelefono = a.tutorExternoTelefono
        ..tutorExternoCvArchivoId = a.tutorExternoCvArchivoId
        ..tutorExternoTituloArchivoId = a.tutorExternoTituloArchivoId;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _guardar() async {
    setState(() => _errores = _form.validar());
    if (_errores.isNotEmpty) return;

    setState(() => _guardando = true);
    final repo = context.read<AppDependencies>().postulacionesRepository;
    try {
      if (_activa == null) {
        final creada = await repo.crear(_form.toJson());
        setState(() => _activa = creada);
        _snack('Postulación creada (borrador).');
      } else {
        final editada = await repo.editar(_activa!.id, _form.toJson());
        setState(() => _activa = editada);
        _snack('Cambios guardados.');
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _enviar() async {
    final a = _activa;
    if (a == null) return;
    setState(() => _enviando = true);
    final repo = context.read<AppDependencies>().postulacionesRepository;
    try {
      final enviada = await repo.enviarASecretaria(a.id);
      setState(() => _activa = enviada);
      _snack('Postulación enviada a secretaría.');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_activa == null ? 'Nueva postulación' : 'Mi postulación'),
      ),
      body: FutureBuilder<void>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudo cargar el formulario.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final a = _activa;
    final puedeEnviar = a != null && esEditable(a.estado) && _declaracion;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (a != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(a.codigoCorto,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              EstadoBadge(estado: a.estado),
            ],
          ),
          const SizedBox(height: 8),
          EstadoBanner(estado: a.estado, motivoRechazo: a.motivoRechazo),
          const SizedBox(height: 8),
          StepperProceso(estado: a.estado),
          const SizedBox(height: 16),
        ],

        // --- Datos del proyecto ---
        Text('Datos del proyecto',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _form.titulo,
          enabled: _editable,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: 'Título del proyecto',
            errorText: _errores['titulo'],
          ),
          onChanged: (v) => _form.titulo = v,
        ),
        DropdownButtonFormField<String>(
          initialValue: _form.modalidad.isEmpty ? null : _form.modalidad,
          decoration: InputDecoration(
            labelText: 'Modalidad',
            errorText: _errores['modalidad'],
          ),
          items: [
            for (final m in _modalidades)
              DropdownMenuItem(value: m, child: Text(m)),
          ],
          onChanged: _editable ? (v) => _form.modalidad = v ?? '' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _form.descripcion,
          enabled: _editable,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Descripción y justificación',
            errorText: _errores['descripcion'],
          ),
          onChanged: (v) => _form.descripcion = v,
        ),
        const SizedBox(height: 20),

        // --- Tutor propuesto ---
        Text('Tutor propuesto', style: Theme.of(context).textTheme.titleMedium),
        RadioListTile<TipoTutor>(
          value: TipoTutor.interno,
          groupValue: _form.tipoTutor,
          title: const Text('Tutor interno'),
          onChanged:
              _editable ? (v) => setState(() => _form.tipoTutor = v!) : null,
        ),
        RadioListTile<TipoTutor>(
          value: TipoTutor.externo,
          groupValue: _form.tipoTutor,
          title: const Text('Tutor externo'),
          onChanged:
              _editable ? (v) => setState(() => _form.tipoTutor = v!) : null,
        ),
        const SizedBox(height: 8),
        if (_form.tipoTutor == TipoTutor.interno)
          _buildTutorInterno(context)
        else
          _buildTutorExterno(context),

        const SizedBox(height: 20),

        // --- Declaracion + acciones ---
        if (a != null)
          CheckboxListTile(
            value: _declaracion,
            onChanged: _editable
                ? (v) => setState(() => _declaracion = v ?? false)
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
                'Declaro que la información proporcionada es veraz y correcta.'),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (!_editable || _guardando) ? null : _guardar,
                child: Text(_guardando
                    ? 'Guardando...'
                    : (a == null ? 'Crear borrador' : 'Guardar cambios')),
              ),
            ),
            if (a != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (!puedeEnviar || _enviando) ? null : _enviar,
                  child: Text(_enviando ? 'Enviando...' : 'Enviar a secretaría'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTutorInterno(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _form.tutorDocenteId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tutor (de la lista de habilitados)',
        errorText: _errores['tutorDocenteId'],
      ),
      items: [
        for (final t in _tutores)
          DropdownMenuItem(value: t.id, child: Text(t.nombre)),
      ],
      onChanged: _editable ? (v) => _form.tutorDocenteId = v : null,
    );
  }

  Widget _buildTutorExterno(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _form.tutorExternoNombres,
          enabled: _editable,
          decoration: InputDecoration(
            labelText: 'Nombres',
            errorText: _errores['tutorExternoNombres'],
          ),
          onChanged: (v) => _form.tutorExternoNombres = v,
        ),
        TextFormField(
          initialValue: _form.tutorExternoApellidos,
          enabled: _editable,
          decoration: InputDecoration(
            labelText: 'Apellidos',
            errorText: _errores['tutorExternoApellidos'],
          ),
          onChanged: (v) => _form.tutorExternoApellidos = v,
        ),
        TextFormField(
          initialValue: _form.tutorExternoCi,
          enabled: _editable,
          decoration: const InputDecoration(labelText: 'CI (opcional)'),
          onChanged: (v) => _form.tutorExternoCi = v,
        ),
        TextFormField(
          initialValue: _form.tutorExternoEmail,
          enabled: _editable,
          decoration: InputDecoration(
            labelText: 'Email (opcional)',
            errorText: _errores['tutorExternoEmail'],
          ),
          onChanged: (v) => _form.tutorExternoEmail = v,
        ),
        TextFormField(
          initialValue: _form.tutorExternoTelefono,
          enabled: _editable,
          decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
          onChanged: (v) => _form.tutorExternoTelefono = v,
        ),
        const SizedBox(height: 12),
        ArchivoUploadField(
          label: 'CV del tutor (PDF)',
          archivoId: _form.tutorExternoCvArchivoId,
          enabled: _editable,
          onChanged: (id) => setState(() => _form.tutorExternoCvArchivoId = id),
        ),
        const SizedBox(height: 12),
        ArchivoUploadField(
          label: 'Título académico (PDF)',
          archivoId: _form.tutorExternoTituloArchivoId,
          enabled: _editable,
          onChanged: (id) =>
              setState(() => _form.tutorExternoTituloArchivoId = id),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/presentation/postulacion_form_screen.dart`
Expected: sin errores. (`EstadoBanner` y `StepperProceso` ya existen de Fase B.)

---

## Task 15: ObservacionesScreen

**Files:**
- Create: `lib/features/postulaciones/presentation/observaciones_screen.dart`

- [ ] **Step 1: Crear la pantalla**

```dart
// lib/features/postulaciones/presentation/observaciones_screen.dart
/// Pantalla "Observaciones" del estudiante. Muestra las observaciones de la
/// postulacion activa (agrupadas por ronda en ObservacionesPanel). Espeja
/// `estudiante/Observaciones.vue`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/observacion.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';
import 'widgets/observaciones_panel.dart';

class ObservacionesScreen extends StatefulWidget {
  const ObservacionesScreen({super.key});

  @override
  State<ObservacionesScreen> createState() => _ObservacionesScreenState();
}

class _ObservacionesScreenState extends State<ObservacionesScreen> {
  late Future<({Postulacion? activa, List<Observacion> obs})> _carga;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<({Postulacion? activa, List<Observacion> obs})> _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias();
    final activa = pickActiva(lista);
    if (activa == null) return (activa: null, obs: <Observacion>[]);
    final detalle =
        await deps.postulacionesRepository.obtenerDetalle(activa.id);
    return (activa: activa, obs: detalle.observaciones);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Observaciones')),
      body: FutureBuilder<({Postulacion? activa, List<Observacion> obs})>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudieron cargar las observaciones.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final data = snapshot.data!;
          if (data.activa == null) {
            return _SinActiva(onIr: () => context.go('/postulacion/nueva'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(data.activa!.titulo,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  EstadoBadge(estado: data.activa!.estado),
                ],
              ),
              const SizedBox(height: 12),
              ObservacionesPanel(observaciones: data.obs),
            ],
          );
        },
      ),
    );
  }
}

class _SinActiva extends StatelessWidget {
  const _SinActiva({required this.onIr});
  final VoidCallback onIr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Todavía no tienes una postulación activa.'),
          const SizedBox(height: 8),
          TextButton(onPressed: onIr, child: const Text('Ir a Nueva postulación')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/presentation/observaciones_screen.dart`
Expected: sin errores. (Verifica que `ObservacionesPanel` reciba `observaciones:` — así se usó en Fase B.)

---

## Task 16: HistorialScreen

**Files:**
- Create: `lib/features/postulaciones/presentation/historial_screen.dart`

- [ ] **Step 1: Crear la pantalla**

```dart
// lib/features/postulaciones/presentation/historial_screen.dart
/// Pantalla "Historial / Trazabilidad": por cada postulacion del estudiante
/// (vigente, observadas, rechazadas, historicas) muestra su cabecera y el
/// timeline de estados. Espeja `estudiante/Historial.vue`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formato.dart';
import '../../shell/presentation/app_drawer.dart';
import '../application/postulacion_actual.dart';
import '../data/models/historial_estado.dart';
import '../data/models/postulacion.dart';
import 'widgets/estado_badge.dart';
import 'widgets/timeline_historial.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<({Postulacion p, List<HistorialEstado> historial})>> _carga;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<List<({Postulacion p, List<HistorialEstado> historial})>>
      _cargar() async {
    final deps = context.read<AppDependencies>();
    final lista = await deps.postulacionesRepository.listarMias()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final activa = pickActiva(lista);
    final res = <({Postulacion p, List<HistorialEstado> historial})>[];
    for (final p in lista) {
      final detalle = await deps.postulacionesRepository.obtenerDetalle(p.id);
      res.add((p: p, historial: detalle.historial));
    }
    // Marca interna de "vigente" la calcula el build comparando con activa.id.
    _activaId = activa?.id;
    return res;
  }

  String? _activaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Historial')),
      body: FutureBuilder<
          List<({Postulacion p, List<HistorialEstado> historial})>>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No se pudo cargar el historial.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Todavía no creaste ninguna postulación.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/postulacion/nueva'),
                    child: const Text('Ir a Nueva postulación'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in items) _seccion(context, item),
            ],
          );
        },
      ),
    );
  }

  Widget _seccion(
    BuildContext context,
    ({Postulacion p, List<HistorialEstado> historial}) item,
  ) {
    final vigente = item.p.id == _activaId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.p.codigoCorto,
                            style: Theme.of(context).textTheme.bodySmall),
                        if (vigente) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            label: Text('Vigente'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                    Text(item.p.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${item.p.modalidad} · ${item.p.tipoTutor.label} · Creada ${formatFecha(item.p.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              EstadoBadge(estado: item.p.estado),
            ],
          ),
          const SizedBox(height: 8),
          TimelineHistorial(historial: item.historial),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze lib/features/postulaciones/presentation/historial_screen.dart`
Expected: sin errores. (Verifica que `TimelineHistorial` reciba `historial:` y que `formato.dart` exponga `formatFecha`, como en Fase B.)

---

## Task 17: Drawer + atajos contextuales en Home y Mis Postulaciones

**Files:**
- Modify: `lib/features/estudiante/presentation/home_estudiante_screen.dart`
- Modify: `lib/features/postulaciones/presentation/mis_postulaciones_screen.dart`

- [ ] **Step 1: Agregar el drawer e importarlo en Home**

En `home_estudiante_screen.dart`, agrega el import:

```dart
import '../../shell/presentation/app_drawer.dart';
import '../../postulaciones/application/postulacion_actual.dart';
```

En el `Scaffold` del `build`, agrega como primera propiedad:

```dart
      drawer: const AppDrawer(),
```

Quita los `IconButton` de "Servidor" y "Cerrar sesión" del `AppBar` (ahora viven en el drawer): borra el `actions: [ ... ]` del `AppBar`.

- [ ] **Step 2: Botones contextuales en el resumen del Home**

En `_ResumenActual.build`, reemplaza el `FilledButton.icon` de "Ver mis postulaciones" por una columna con los atajos según el estado:

```dart
        if (esEditable(p.estado)) ...[
          FilledButton.icon(
            onPressed: () => context.push('/postulacion/nueva'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar / Enviar'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: () => context.push('/mis-postulaciones'),
          icon: const Icon(Icons.folder_shared_outlined),
          label: Text(
            total > 1 ? 'Ver mis postulaciones ($total)' : 'Ver mis postulaciones',
          ),
        ),
```

(El import de `postulacion_actual.dart` en el Step 1 habilita `esEditable`.)

- [ ] **Step 3: Botón "Crear" en el estado vacío del Home**

En `_SinPostulaciones.build`, después del último `Text(...)` dentro del `Column`, agrega:

```dart
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/postulacion/nueva'),
              icon: const Icon(Icons.add),
              label: const Text('Crear postulación'),
            ),
```

Asegúrate de que el archivo tenga el import de go_router (`package:go_router/go_router.dart`) — ya lo tiene de Fase B.

- [ ] **Step 4: Drawer en Mis Postulaciones**

En `mis_postulaciones_screen.dart`, agrega el import:

```dart
import '../../shell/presentation/app_drawer.dart';
```

En su `Scaffold`, agrega como primera propiedad:

```dart
      drawer: const AppDrawer(),
```

- [ ] **Step 5: Checkpoint**

Run: `flutter analyze`
Expected: sin errores (solo los `info` de estilo previos).

---

## Task 18: Verificación final

**Files:** —

- [ ] **Step 1: Análisis estático completo**

Run: `flutter analyze`
Expected: "No issues found!" o solo los `info - prefer_initializing_formals` ya conocidos. Cero `error`/`warning`.

- [ ] **Step 2: Toda la batería de tests**

Run: `flutter test`
Expected: todos en verde (los nuevos: postulacion_actual, postulacion_form_data, tutor_option, modalidades; más los de Fase A/B).

- [ ] **Step 3: Prueba manual en el teléfono (guía)**

Con backend + túnel corriendo y la URL del túnel cargada en la app:

Run: `flutter run --dart-define=API_BASE_URL=https://TU-URL.trycloudflare.com`

Verifica:
1. Abrir el **drawer** (☰): aparecen los 8 ítems; Documentos/Carta/Perfil atenuados ("Próximamente"); el ítem actual resaltado.
2. Sin postulación activa → "Nueva Postulación" muestra el formulario vacío. Crear un borrador con tutor interno → vuelve prellenado y aparece en el Home.
3. Editar el borrador (cambiar título, guardar) → "Cambios guardados".
4. Cambiar a tutor externo → adjuntar un PDF de CV (≤10 MB) → muestra el nombre y check verde.
5. Marcar la **declaración de veracidad** → "Enviar a secretaría" → el estado pasa a "Nuevo" (ENVIADO) y el formulario queda readonly.
6. **Observaciones** e **Historial** muestran la info de la activa / de todas.

---

## Self-review (cobertura del spec)

- Navegación Drawer con 8 ítems + atenuados Tanda 2 → Tasks 11, 12, 17. ✅
- Una activa a la vez (`pickActiva`) → Task 3. ✅
- Botón "Crear" contextual en Home → Task 17. ✅
- Crear / editar / enviar → Tasks 4, 5, 14. ✅
- Subir PDFs (file_picker + multipart) → Tasks 1, 6, 13. ✅
- Tutor interno (habilitados ⨝ docentes) → Tasks 7, 8, 14. ✅
- Modalidades endpoint + fallback → Task 9, 14. ✅
- Estados editables/readonly + declaración de veracidad → Tasks 3, 14. ✅
- Observaciones e Historial como pantallas → Tasks 15, 16. ✅
- Manejo de errores con `detail` del backend → vía `ApiException` en todos los repos. ✅
- Tests (payload, validación, tutor option, modalidades, activa) → Tasks 3, 4, 7, 9. ✅
- Fuera de alcance (Documentos descarga, Carta, Perfil) → atenuados, no implementados (Tanda 2). ✅
